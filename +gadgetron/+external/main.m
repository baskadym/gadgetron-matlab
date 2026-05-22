
function main()

    % Workaround for occasional blank windows when Matlab run as root (as in container)
    % https://uk.mathworks.com/support/bugreports/details/2794932
    % Fixed in Matlab R2023a
    setenv('MW_CEF_STARTUP_OPTIONS', '--in-process-gpu');
    
    port = getenv('GADGETRON_EXTERNAL_PORT');
    module = getenv('GADGETRON_EXTERNAL_MODULE');
    
    if isempty(port) || isempty(module)
        fprintf("Gadgetron External MATLAB Module\n");
        return
    end
    
    fprintf("Starting external MATLAB module '%s' in state: [ACTIVE]\n", module)
    fprintf("Connecting to parent on port %s\n", port)
    
    sock = socket.connect('localhost', str2num(port));
    connection = gadgetron.external.Connection(sock);
    
    feval(module, connection);
end

