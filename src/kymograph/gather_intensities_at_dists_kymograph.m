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

if (exist(fullfile('..','shared'),'dir') == 7)
    addpath(fullfile('..','shared'));
end

send_message('Gathering Data...');

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
    
    send_message(['STATUS: Done with ',image_files(i).name]);
end

while (isempty(pixels_at_dists_pre{end}))
    pixels_at_dists_pre = pixels_at_dists_pre(1:(end - 1));
end

while (isempty(pixels_at_dists_post{end}))
    pixels_at_dists_post = pixels_at_dists_post(1:(end - 1));
end

save(fullfile(I_folder,'pixel_values.mat'),'pixels_at_dists_pre','pixels_at_dists_post','dist_means');

end