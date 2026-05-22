function [sens, noise_cov] = vrc_phase_correction(sens, ref_mag, PPIparams, N_coils, gadNoiseDir, scaleNoiseCov, vrc_mask_thr, noise_cov_power)
%**************************************************************************
%
%   vrc_phase_correction
%
%       input   sens: image space sensitivities [RO, PE1, PE2, N_order, N_coils]
%               ref_mag: root sum of squares of separate channel reference magnitude data
%               PPIparams: PPI parameters structure
%               N_coils: number of coils
%               gadNoiseDir: location of noise covariance matrix
%               scaleNoiseCov: empirical scaling for numerical stability
%               vrc_mask_thr: threshold for VRC mask creation (fraction of mean)
%               noise_cov_power: power to which noise covariance matrix is raised during correlation
%
%       output  sens: image space sensitivities after VRC correction [RO, PE1, PE2, N_order, N_coils]
%               noise_cov: the noise covariance matrix
%**************************************************************************
global smap_noise_cov
measID = PPIparams.measID;

noise_cov    = [];
do_correlate = false;

%% ------------------------------------------------------------
% Load noise covariance matrix
% ------------------------------------------------------------

if strcmp(PPIparams.refType,'separate')

    disp('Separate calibration data - using noise covariance matrix from a previous scan')
    if numel(smap_noise_cov) > 1
        disp('Loading noise covariance matrix')
        noise_cov    = smap_noise_cov;
        do_correlate = true;
    else
        warning('No noise covariance from smap acquisition')
    end

else
    disp('Fully sampled or integrated calibration data - loading noise covariance from the same scan')

    dirc = dir(gadNoiseDir);
    dirc = dirc(~[dirc.isdir]);   % keep only files

    if isempty(dirc)
        warning('No noise covariance matrix available')
    else
        [~, idx] = max([dirc.datenum]);
        fname   = fullfile(dirc(idx).folder, dirc(idx).name);

        txt = fileread(fname);
        measIDs = extractBetween(txt,'<measurementID>','</measurementID>');

        if strcmp(measID, measIDs{1})
            disp('Loading noise covariance matrix')
            fid = fopen(fname);
            fseek(fid, -N_coils*N_coils*8, 1);
            noise_val = fread(fid,'single=>single');
            fclose(fid);

            noise_val = reshape(noise_val,[2 N_coils N_coils]);
            noise_cov = squeeze(noise_val(1,:,:) + ...
                                1i*noise_val(2,:,:)) * scaleNoiseCov;
            do_correlate = true;
        else
            warning('Measurement ID mismatch – skipping noise_cov phase correlation')
        end
    end
end

%% ------------------------------------------------------------
% Correlate (unwhiten) sensitivities if possible
% ------------------------------------------------------------

sens_corr = sens(:,:,:,1,:);

if do_correlate
    disp('Correlating sensitivities for robust VRC estimation')
    sz        = size(sens_corr);
    sens_mat = reshape(sens_corr,[],N_coils);
    sens_mat = sens_mat * chol(noise_cov,'upper')^noise_cov_power;
    sens_corr = reshape(sens_mat,sz);
end

%% ------------------------------------------------------------
% VRC phase correction
% ------------------------------------------------------------

disp('VRC phase correction')

% Seed voxel selection
mask  = imbinarize(ref_mag, mean(ref_mag(:)) * vrc_mask_thr);
props = regionprops3(mask, ref_mag, 'WeightedCentroid','Volume');

[~, idx] = max(props.Volume);
centroid = round(props.WeightedCentroid(idx,[2 1 3]));

% Coil-wise phase-matching at a seed voxel
sens_diff = zeros(size(sens_corr),'like',sens_corr);
for ch = 1:N_coils
    sens_diff(:,:,:,1,ch) = sens_corr(:,:,:,1,ch) .* exp(-1i*angle(sens_corr(centroid(1),centroid(2),centroid(3),1,ch)));
end

% Remove VRC phase from coil sensitivites
sens_sum = sum(sens_diff,5);
sens(:,:,:,1,:) = sens(:,:,:,1,:) .* exp(-1i*angle(sens_sum));

end
