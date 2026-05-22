%% write_to_disk

%**************************************************************************
%
%   Writing data to disk for later use. Developed for writing sensitivities
%   acquired separately (s-map) for later use in unfolding.
%       input:          Structure with data field
%       gadNoiseDir:    Gadgetron store directory
%       header:         Measurement information. Used for ID retrieval via get_PPI_Params
%
%**************************************************************************

function next = write_to_disk(input, gadNoiseDir, header)

disp("Writing data to disk...")

    function data = write_to_disk(data)

        disp("Writing data to disk...")
        
        data.protocol = header.measurementInformation.protocolName;

        % The measurementID remains consistent bar the final digits, which
        % are the MeasID as seen in TWIX:
        data.MeasID = header.measurementInformation.measurementID;

        % File to write to remove data.data since already sent to database 
        % (assumes create_ismrmrd_3Dvol_and_send preceeds it in the chain)   
        fileName = fullfile([gadNoiseDir filesep 'database-FIL'], [data.MeasID '_sensitivity.mat']);

        % Write file:
        save(fileName, 'data', '-v7.3');

    end

next = @() write_to_disk(input());
end
