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

function gather_intensities_at_dists_kymograph(I_folder,cali_time,distance_bin_size,pixel_size, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'GATHER_INTENSITIES_AT_DISTS_KYMOGRAPH';

i_p.addRequired('I_folder',@(x)exist(x,'dir') == 7);
i_p.addRequired('cali_time',@(x)isnumeric(x) & x > 0);
i_p.addRequired('distance_bin_size',@(x)isnumeric(x) & x > 0);
i_p.addRequired('pixel_size',@(x)isnumeric(x) & x > 0);

i_p.addParamValue('cell_edge_id_threshold',400,@(x)isnumeric(x) & x > 0);

i_p.parse(I_folder,cali_time,distance_bin_size,pixel_size,varargin{:});

cell_edge_id_threshold = i_p.Results.cell_edge_id_threshold;

global status_text_hnd;
set(status_text_hnd,'String','Gathering Data...'); drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pixels_at_dists_pre = cell(10000,1);
pixels_at_dists_post = cell(10000,1);

dist_means = [];

image_files = dir(I_folder);
assert(image_files(1).name == '.')
assert(all(image_files(2).name == '..'))
image_files = image_files(3:end);

for i=1:length(image_files)
    if (exist(fullfile(I_folder,image_files(i).name),'dir'))
        continue;
    end 
    
    [junk_1, name_no_ext, junk_2, junk_3] = fileparts(image_files(i).name); %#ok<NASGU>

    diagnostics_path = fullfile(I_folder,'diagnostics');
    
    if (not(exist(diagnostics_path)))
        mkdir(diagnostics_path);
    end
    try
        this_image = imread(fullfile(I_folder,image_files(i).name));
    catch IE %#ok<NASGU>
        continue;
    end
    
    this_image_no_scale = this_image;
    max_pix_val = double(intmax(class(this_image)));
    this_image = double(this_image)/max_pix_val;
    
    cell_mask = im2bw(this_image, cell_edge_id_threshold/max_pix_val);
    cleaned_mask = clean_up_cell_mask(cell_mask);
    
    normed_image = (this_image - min(this_image(:)))/(max(this_image(:)) - min(this_image(:)));
    mask_highlight = create_highlighted_image(normed_image,bwperim(cleaned_mask));
    imwrite(mask_highlight,fullfile(diagnostics_path,['mask_highlight_',name_no_ext,'.png']));
    
    pre_cali_cols = 1:cali_time;
    post_cali_cols = (cali_time+1):size(this_image,1);
    
    for j = pre_cali_cols
        this_image_col = this_image_no_scale(:,j);
        this_mask_col = cell_mask(:,j);
        
        dists = bwdist(~this_mask_col)*pixel_size;
        distance_bins = 0:distance_bin_size:max(dists);
        
        temp_dist_means = [];
        for k=1:(length(distance_bins)-1)
            these_dist_pixels = this_image_col(dists > distance_bins(k) & dists <= distance_bins(k+1));
            pixels_at_dists_pre(k) = {[[pixels_at_dists_pre{k}]; these_dist_pixels]};
            temp_dist_means = [temp_dist_means, mean(distance_bins(k:(k+1)))]; %#ok<AGROW>
        end
        
        if (length(temp_dist_means) > length(dist_means))
            dist_means = temp_dist_means;
        end
    end
    
    for j = post_cali_cols
        this_col = this_image_no_scale(:,j);
        
        this_image_col = this_image_no_scale(:,j);
        this_mask_col = cell_mask(:,j);
        
        dists = bwdist(~this_mask_col)*pixel_size;
        distance_bins = 0:distance_bin_size:max(dists);
        
        temp_dist_means = [];
        for k=1:(length(distance_bins)-1)
            these_dist_pixels = this_image_col(dists > distance_bins(k) & dists <= distance_bins(k+1));
            pixels_at_dists_post(k) = {[[pixels_at_dists_post{k}]; these_dist_pixels]};
            temp_dist_means = [temp_dist_means, mean(distance_bins(k:(k+1)))]; %#ok<AGROW>
        end
        
        if (length(temp_dist_means) > length(dist_means))
            dist_means = temp_dist_means;
        end
        
    end
    
    if (exist('status_text_hnd','var'))
        set(status_text_hnd,'String',['STATUS: Done with ',image_files(i).name]);
        drawnow;
    end
end

% set(status_text_hnd,'String',['STATUS: done examining image data']);
% drawnow;

while (isempty(pixels_at_dists_pre{end}))
    pixels_at_dists_pre = pixels_at_dists_pre(1:(end - 1));
end

while (isempty(pixels_at_dists_post{end}))
    pixels_at_dists_post = pixels_at_dists_post(1:(end - 1));
end

save(fullfile(I_folder,'pixel_values.mat'),'pixels_at_dists_pre','pixels_at_dists_post','dist_means');

end

function cleaned_mask=clean_up_cell_mask(cell_mask)

labeled_mask = bwlabel(cell_mask,4);

areas = regionprops(labeled_mask,'Area');

cleaned_mask = ismember(labeled_mask, find([areas.Area] == max([areas.Area])));

cleaned_mask = imfill(cleaned_mask,'holes');

end

function high_image = create_highlighted_image(I,high,varargin)
%CREATE_HIGHLIGHTED_IMAGE    add highlights to an image
%
%   H_I = create_highlighted_image(I,HIGHLIGHTS) adds green highlights to
%   image 'I', using the binary image 'HIGHLIGHTS' as the guide
%
%   H_I = create_highlighted_image(I,HIGHLIGHTS,'color_map',[R,G,B]) adds
%   highlights of color specified by the RGB sequence '[R,G,B]' to image
%   'I', using the binary image 'HIGHLIGHTS' as the guide

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'CREATE_HIGHLIGHTED_IMAGE';

i_p.addRequired('I',@(x)isnumeric(x) || islogical(x));
i_p.addRequired('high',@(x)(isnumeric(x) || islogical(x)));

i_p.parse(I,high);

i_p.addParamValue('color_map',[0,1,0],@(x)(all(high(:) == 0) || (isnumeric(x) && (size(x,1) >= max(unique(high))))));
i_p.addParamValue('mix_percent',1,@(x)(isnumeric(x)));

i_p.parse(I,high,varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
image_size = size(I);

if (size(image_size) < 3)
    high_image_red = I;
    high_image_green = I;
    high_image_blue = I;
else
    high_image_red = I(:,:,1);
    high_image_green = I(:,:,2);
    high_image_blue = I(:,:,3);
end

if (all(high(:) == 0))
    high_image = cat(3,high_image_red,high_image_green,high_image_blue);
    return
end

labels = unique(high);
assert(labels(1) == 0)
labels = labels(2:end);

for i=1:length(labels)
    indexes = high == labels(i);
    
    this_cmap = i_p.Results.color_map(labels(i),:);
    
    high_image_red(indexes) = this_cmap(1)*i_p.Results.mix_percent + high_image_red(indexes)*(1-i_p.Results.mix_percent);
    high_image_green(indexes) = this_cmap(2)*i_p.Results.mix_percent + high_image_green(indexes)*(1-i_p.Results.mix_percent);
    high_image_blue(indexes) = this_cmap(3)*i_p.Results.mix_percent + high_image_blue(indexes)*(1-i_p.Results.mix_percent);
end

high_image = cat(3,high_image_red,high_image_green,high_image_blue);

end

function analyze_cali(data_dir)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'analyze_cali';

i_p.addRequired('data_dir',@(x)exist(x,'dir') == 7);

i_p.parse(data_dir);

global status_text_hnd;
set(status_text_hnd,'String','Processing Data...'); drawnow;

pixels_temp = load(fullfile(data_dir,'pixel_values.mat'));
% pixels_at_dists_post = load(fullfile(data_dir,'pixel_values_post.mat'));

pixels_at_dists_pre = pixels_temp.pixels_at_dists_pre;
pixels_at_dists_post = pixels_temp.pixels_at_dists_post;
dist_means = pixels_temp.dist_means;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

summary_pre = zeros(3,length(pixels_at_dists_pre));
summary_post = zeros(3,length(pixels_at_dists_post));

for i=1:length(pixels_at_dists_pre)
    if (isempty(pixels_at_dists_pre{i}))
        summary_pre(1,i) = 0;
        summary_pre(2,i) = 0;
        summary_pre(3,i) = 0;
    end
    
    summary_pre(1,i) = mean(pixels_at_dists_pre{i});
    
    boot_temp = bootci(1000,{@mean,pixels_at_dists_pre{i}},'type','per');
    
    summary_pre(2,i) = boot_temp(1);
    summary_pre(3,i) = boot_temp(2);
    
    if (exist('status_text_hnd','var'))
        set(status_text_hnd,'String',['STATUS: Done with pre-CALI depth layer ', num2str(i), '/', num2str(length(pixels_at_dists_pre))]);
        drawnow;
    else
        disp(['STATUS: Done with pre-CALI depth layer ', num2str(i), '/', num2str(length(pixels_at_dists_pre))]);
    end
end
if (exist('status_text_hnd','var'))
    set(status_text_hnd,'String','STATUS: Done with processing pre-CALI data'); drawnow;
end
for i=1:length(pixels_at_dists_post)
    summary_post(1,i) = mean(pixels_at_dists_post{i});
    
    boot_temp = bootci(1000,{@mean,pixels_at_dists_post{i}},'type','per');
    
    summary_post(2,i) = boot_temp(1);
    summary_post(3,i) = boot_temp(2);
    if (exist('status_text_hnd','var'))
        set(status_text_hnd,'String',['STATUS: Done with processing post-CALI depth layer ', num2str(i), '/', num2str(length(pixels_at_dists_pre))]);
        drawnow;        
    else
        disp(['STATUS: Done with processing post-CALI depth layer ', num2str(i), '/', num2str(length(pixels_at_dists_pre))]);
    end

end

if (exist('status_text_hnd','var'))
    set(status_text_hnd,'String','STATUS: Done with processing post-CALI data'); drawnow;
end

%Results output to CSV files
summary_pre_header = [dist_means(1:length(summary_pre(1,:)));summary_pre];
summary_post_header = [dist_means(1:length(summary_post(1,:)));summary_post];

dlmwrite(fullfile(data_dir,'pre_cali_mean_intensities.csv'),summary_pre_header);
dlmwrite(fullfile(data_dir,'post_cali_mean_intensities.csv'),summary_post_header);

%Summary Figure
temp_fig = figure('Visible','off');
fig_hnd = errorbar(dist_means(1:length(summary_pre(1,:))), summary_pre(1,:), ...
    summary_pre(1,:)-summary_pre(2,:), summary_pre(1,:)-summary_pre(3,:));

xlabel('Mean Distance from Nearest Cell Edge (\mum)')
ylabel('Average Intensity (AU)')
hold on;
errorbar(dist_means(1:length(summary_post(1,:))), summary_post(1,:), ...
    summary_post(1,:)-summary_post(2,:), summary_post(1,:)-summary_post(3,:),'r');
legend('Pre-Cali','Post-Cali')
saveas(temp_fig,fullfile(data_dir,'cort_actin_intensity.pdf'))

if (exist('status_text_hnd','var'))
    set(status_text_hnd,'String','STATUS: Done with processing extracted data'); drawnow;
end

end