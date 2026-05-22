
function ReconBSS(connection)
    disp("Matlab B1 BSS recon launched...")

    recon_type = 'MORSE' ; % 'MORSE' or 'ESPIRiT', 'ESPIRiT' recquires installation of the Berkeley Advanced Reconstruction Toolbox (BART) toolbox 

    % Hard-coded reconstruction parameters:
    global onlineROFT scaleKsp gadNoiseDir scaleNoiseCov ph_correction vrc_mask_thr noise_cov_power w N_ref N_order lambda

    N_order = 1;
    scaleFactor = 448e3; % % empirically established for 4 mm isotropic B1 map at 7T, that exact value for back-compatibility, gets scaled by the voxel volume and field strength in create_ismrmrd_3Dvol_and_send
    windowFactor = 0.4; % for cosine filter 0.2, for Tukey filter 0.4

    if strcmp(recon_type, 'MORSE')
        scaleKsp    = 100;
        w          = 4;
        N_ref    = 4 ;
        lambda      = 3e-4;

        gadNoiseDir = '~/.gadgetron/storage';       % gadgetron noise_cov storage directory, default is '~/.gadgetron/storage', can be changed with gadgetron -S option
        scaleNoiseCov       = 10^11;                % Noise covariance scaling factor - for numerical stability
        ph_correction = 'VRC';                      % 'VRC' - Virtual Reference Coil, i.e. subtraction of phase-matched sum of coil sensitivities
        vrc_mask_thr    = 0.8;                      % for VRC phase correction: threshold used to create a mask, centroid of this mask is a seed voxel for VRC phase correction, smaller values = bigger mask
        noise_cov_power = 2;                        % for VRC phase correction: exponent applied to noise covariance matrix to correlate coils and establish good VRC support over entire ROI, higher values more correlation

        onlineROFT      = false;
        PPIparams = gadgetron.FIL.utils.get_PPI_params(connection.header);

    elseif strcmp(recon_type, 'ESPIRiT')
        dimRef = [12,12,12];
    else
        error('specify recon_type as MORSE or ESPIRiT in ReconBSS.m')
    end


    % Specified reconstruction steps
    next = gadgetron.FIL.steps.accumulate_volume(@connection.next, connection.header);
    next = gadgetron.FIL.steps.tukey_filter(next,windowFactor, PPIparams);
    if strcmp(recon_type, 'MORSE')
        next = gadgetron.FIL.steps.morse_calc_sens(next,PPIparams);
        next = gadgetron.FIL.steps.morse_unfold(next, connection.header);
    elseif strcmp(recon_type, 'ESPIRiT')
        next = gadgetron.FIL.steps.ESPIRiT_calc_sens(next,dimRef);
        next = gadgetron.FIL.steps.ESPIRiT_unfold(next, connection.header);
    end
    next = gadgetron.FIL.steps.BSS_classic_or_GLM_B1map(next, connection.header);
    next = gadgetron.FIL.steps.create_ismrmrd_3Dvol_and_send(next, connection, scaleFactor);
    tic, gadgetron.consume(next); toc
end
