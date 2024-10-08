function [unwrapped, B0] = ROMEO(phase, parameters)
    
    romeo_name = 'romeo';
    
    output_dir = pwd();
    if isfield(parameters, 'output_dir')
        output_dir = parameters.output_dir;
    end
    
    % Input Files
    fn_phase = fullfile(output_dir, 'Phase.nii');
    fn_mask = fullfile(output_dir, 'Mask.nii');
    fn_mag = fullfile(output_dir, 'Mag.nii');
    
    phase_nii = make_nii(phase);
    if isfield(parameters, 'voxel_size')
        phase_nii.hdr.dime.pixdim(2:4) = parameters.voxel_size;
    end
    save_nii(phase_nii, fn_phase);
    if isfield(parameters, 'mag') && ~isempty(parameters.mag)
        save_nii(make_nii(parameters.mag), fn_mag);
    end
    if isfield(parameters, 'mask') && isnumeric(parameters.mask)
        save_nii(make_nii(parameters.mask), fn_mask);
    end
    
    % Output Files
    fn_unwrapped = fullfile(output_dir, 'Unwrapped.nii');
    fn_total_field = fullfile(output_dir, 'B0.nii');
    
    % Always required parameters
    cmd_phase = [' -p ' fn_phase];
    cmd_output = [' -o ' fn_unwrapped];
    
    % Optional parameters
    cmd_calculate_B0 = '';
    if isfield(parameters, 'calculate_B0') && parameters.calculate_B0
        cmd_calculate_B0 = ' -B';
    end
    cmd_mag = '';
    if isfield(parameters, 'mag') && ~isempty(parameters.mag)
        cmd_mag = [' -m ' fn_mag];
    end
    cmd_echo_times = '';
    if isfield(parameters, 'TE')
        cmd_echo_times = [' -t ' mat2str(parameters.TE)];
    end
    cmd_mask = '';
    if isfield(parameters, 'mask')
        if isnumeric(parameters.mask)
            cmd_mask = [' -k ' fn_mask];
        else
            cmd_mask = [' -k ' parameters.mask];
        end
    end
    cmd_phase_offset_correction = '';
    if isfield(parameters, 'phase_offset_correction')
        cmd_phase_offset_correction = [' --phase-offset-correction ' parameters.phase_offset_correction];
    end
    additional_flags = '';
    if isfield(parameters, 'additional_flags')
        additional_flags = [' ' parameters.additional_flags];
    end
    
    % Create romeo CMD command
    romeo_cmd = ['sudo ' romeo_name cmd_phase cmd_mag cmd_output cmd_echo_times cmd_mask cmd_calculate_B0 cmd_phase_offset_correction additional_flags];
    disp(['ROMEO command: ' romeo_cmd])
    
    % Run romeo
    success = system(romeo_cmd); % system() call should work on every machine
    
    if success ~= 0
        error(['ROMEO unwrapping failed! Check input files for corruption in ' output_dir]);
    end
    
    % Load the calculated output
    B0 = [];
    unwrapped = [];
    if isfield(parameters, 'calculate_B0') && parameters.calculate_B0
        B0 = load_untouch_nii(fn_total_field).img;
    end
    if ~isfield(parameters, 'no_unwrapped_output') || ~parameters.no_unwrapped_output
        unwrapped = load_untouch_nii(fn_unwrapped).img;
    end
end
