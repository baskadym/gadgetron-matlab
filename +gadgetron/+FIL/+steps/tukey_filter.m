%**************************************************************************
%
%   tukey_filter applies a filter in 3D given windowFactor
%       input "data" contains:
%               a global header in .reference
%               k-space in .data as [N_coils, RO, PE1, PE2, echoes, sets]
%
%       output "data" contains:
%               a global header in .reference
%               filtered k-space in .data as
%                   [N_coils, RO, PE1, PE2, echoes, sets]
%
%**************************************************************************


function next = tukey_filter(input, windowFactor, PPIparams)

disp("Tukey filter setup...")

    function data = tukey_filter(data)

        disp("Applying Tukey filter...")

        % smooths the edges of the k-space in all three directions to avoid ringing artefatcs
        % accounts for partial Fourier

        dims = size(data.data);
        dat=reshape(data.data,dims(1),dims(2),dims(3),dims(4),[]);
        RO= dims(2) ;
        k_width_acq_PE1 = PPIparams.kmax_PE1 - PPIparams.kmin_PE1 + 1;
        k_width_acq_PE2 = PPIparams.kmax_PE2 - PPIparams.kmin_PE2 + 1;

        datFiltered = permute(zeros(size(dat), 'single'),[2 3 4 1 5]);
        for vol=1:size(dat,5)
          % Permute dat to [RO, PE1, PE2, N_coils]
            datToFilt = permute(squeeze(dat(:,:,:,:,vol)),[2 3 4 1]);

            % Tukeywin starts and ends with zeros therefore add 2 voxels and then remove
            tw_RE=tukeywin(RO+2,windowFactor);
            tw_PE1=tukeywin(k_width_acq_PE1+2, windowFactor);
            tw_PE2=tukeywin(k_width_acq_PE2+2, windowFactor);
            [w_RE, w_PE1, w_PE2] = ndgrid(tw_RE(2:end-1),tw_PE1(2:end-1),tw_PE2(2:end-1));
            tw3D=w_RE.*w_PE1.*w_PE2 ;
         
            % Apply to reference data to minimise Gibbs ringing
            refmask = any(datToFilt,4);               % [RO PE1 PE2]
            refwin = zeros(size(refmask), 'single');  % [RO PE1 PE2]
            refwin(refmask) = tw3D;                   % sets non-zero entries
            datFiltered(:,:,:,:,vol) = datToFilt.*refwin ;

        end

        data.data=reshape(permute(datFiltered,[4 1 2 3 5]),size(data.data));

    end


next = @() tukey_filter(input());
end
