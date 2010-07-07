function cali_kymograph_gui

%  Create and then hide the GUI as it is being constructed.
f = figure('Visible','off','Name','CALI Kymograph Analysis','Units','normalized', ...
    'Position',[0.1,0.1,0.5,0.5],'WindowStyle','docked');

path_name = uigetdir('*','Please select the folder containing the kymographs you want to analyze');

set(f,'Visible','on');

if (~ path_name)
    error('Restart the GUI and please pick a file');
    close(f);
end

uicontrol(f,'Style','text','String', ['Folder to Process:',path_name], ...
    'Units','normalized','Position',[0.05,0.90,0.9,0.05]);

%Image Processing Options
uicontrol(f,'Style','text','String','Edge Threshold','Units','normalized','Position',[0.05,0.8,0.20,0.05]);
edge_thresh_box = uicontrol(f,'Style','edit','String','400','Units','normalized','Position',[0.25,0.8,0.20,0.05]);

uicontrol(f,'Style','text','String','CALI Time','Units','normalized','Position',[0.5,0.8,0.20,0.05]);
cali_time_box = uicontrol(f,'Style','edit','String','20','Units','normalized','Position',[0.7,0.8,0.20,0.05]);

uicontrol(f,'Style','text','String','Distance Bin Width','Units','normalized','Position',[0.05,0.7,0.20,0.05]);
distance_bins_box = uicontrol(f,'Style','edit','String','4','Units','normalized','Position',[0.25,0.7,0.20,0.05]);

uicontrol(f,'Style','text','String','Pixel Size (um)','Units','normalized','Position',[0.5,0.7,0.20,0.05]);
pixel_size_box = uicontrol(f,'Style','edit','String','1','Units','normalized','Position',[0.7,0.7,0.20,0.05]);

%Program Exection Options
uicontrol(f,'Style','text','String','Step 1: Processing the Images','Units','normalized', ...
    'Position',[0.05,0.6,0.4,0.05], 'BackgroundColor',[0.8,0.8,0.8]);

step_1_hnd = uicontrol(f,'Style','pushbutton','String','Start Processing Images','Units','normalized', ...
    'callback',{@gather_intensities_at_dists_callback}, ...
    'Position',[0.05,0.55,0.4,0.05]);

uicontrol(f,'Style','text','String','Step 2: Processing the extracted data','Units','normalized', ...
    'Position',[0.05,0.4,0.4,0.05], 'BackgroundColor',[0.8,0.8,0.8]);

data_processing_hnd = uicontrol(f,'Style','pushbutton','String','Start Processing Data File','Units','normalized', ...
    'callback',{@analyse_cali_callback}, ...
    'Position',[0.05,0.35,0.4,0.05], 'enable','off');

if (exist(fullfile(path_name,'pixel_values.mat'),'file'))
    set(data_processing_hnd,'enable','on');
end

do_both_hnd = uicontrol(f,'Style','pushbutton','String','Do Step 1 and Step 2','Units','normalized', ...
    'callback',{@do_both_callback}, ...
    'Position',[0.5,0.35,0.4,0.30], 'enable','on');


global status_text_hnd;

status_text_hnd = uicontrol(f,'Style','text','String','STATUS: Waiting for User Input', ...
    'Units','normalized','Position',[0.05,0.05,0.9,0.05]);

    function gather_intensities_at_dists_callback(source,eventdata)
        edge_thresh = str2double(get(edge_thresh_box,'String'));
        cali_time = str2double(get(cali_time_box,'String'));
        distance_bins = str2double(get(distance_bins_box,'String'));
        pixel_size = str2double(get(pixel_size_box,'String'));
        
        set(step_1_hnd,'enable','off')
        set(step_1_hnd,'String','Working...')
        drawnow;
        gather_intensities_at_dists_kymograph(path_name,cali_time,distance_bins,pixel_size,...
            'cell_edge_id_threshold',edge_thresh);
        set(step_1_hnd,'enable','on')
        set(step_1_hnd,'String','Re-process the Images')
        
        set(data_processing_hnd,'enable','on');
    end

    function analyse_cali_callback(source, eventdata)
        analyze_cali(path_name);
    end

    function do_both_callback(source, eventdata)
        
        set(do_both_hnd,'enable','off')
        
        gather_intensities_at_dists_callback(source,eventdata)
        analyse_cali_callback(source,eventdata);
        
        set(do_both_hnd,'enable','on')
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







