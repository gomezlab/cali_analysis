function send_message(message,varargin)

i_p = inputParser;

i_p.addRequired('message',@ischar);

i_p.parse(message,varargin{:});

global status_text_hnd;

if (isempty(status_text_hnd))
    disp(message);
else
    try
        set(status_text_hnd,'String',message); drawnow;
    catch
        disp(message);
    end
end

end