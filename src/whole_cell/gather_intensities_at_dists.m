function gather_intensities_at_dists(I_folder,cali_time,distance_bin_sizes,pixel_size, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'GATHER_INTENSITIES_AT_DISTS';

i_p.addRequired('I_folder',@(x)exist(x,'dir') == 7);
i_p.addRequired('cali_time',@(x)isnumeric(x) & x > 0);
i_p.addRequired('distance_bin_sizes',@(x)isnumeric(x) & x > 0);
i_p.addRequired('pixel_size',@(x)isnumeric(x) & x > 0);

i_p.addParamValue('cell_edge_id_threshold',400,@(x)isnumeric(x) & x > 0);

i_p.parse(I_folder,cali_time,distance_bin_sizes,pixel_size,varargin{:});

cell_edge_id_threshold = i_p.Results.cell_edge_id_threshold;

if (exist(fullfile('..','shared'),'dir') == 7)
    addpath(fullfile('..','shared'));
end

send_message('Gathering Data...');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
image_files = dir(fullfile(I_folder,'*.tif*'));

pixels_at_dists_pre = cell(10000,1);
pixels_at_dists_post = cell(10000,1);
dist_means = [];

for k = 1:length(image_files)
    
    I_file = fullfile(I_folder,image_files(k).name);
    
    [path, name, ext] = fileparts(I_file);
    
    image_num = length(imfinfo(I_file));
    
    cell_highlight_movie = avifile(fullfile(fileparts(I_file),[name,'_mask_highlight.avi']));
    dist_highlight_movie = avifile(fullfile(fileparts(I_file),[name,'_dist_highlight.avi']));
    
    for i=1:image_num
        
        this_image = imread(I_file,i);
        this_image_no_scale = this_image;
        max_pix_val = double(intmax(class(this_image)));
        this_image = double(this_image)/max_pix_val;
        
        cell_mask = im2bw(this_image, cell_edge_id_threshold/max_pix_val);
        cleaned_mask = clean_up_cell_mask(cell_mask);
        
        normed_image = (this_image - min(this_image(:)))/(max(this_image(:)) - min(this_image(:)));
        mask_highlight = create_highlighted_image(normed_image,bwperim(cleaned_mask));
        cell_highlight_movie = addframe(cell_highlight_movie,mask_highlight);
        
        dists = bwdist(~cleaned_mask)*pixel_size;
        distance_bins = 0:distance_bin_sizes:max(dists(:));
        
        dist_label = zeros(size(dists));
        
        temp_dist_means = [];
        for j=1:(length(distance_bins)-1)
            dist_label(dists > distance_bins(j) & dists <= distance_bins(j+1)) = j;
            temp_dist_means = [temp_dist_means, mean(distance_bins(j:(j+1)))];
        end
        
        if (length(temp_dist_means) > length(dist_means))
            dist_means = temp_dist_means;
        end
        
        color_dist_label = label2rgb(dist_label);
        dist_highlight_movie = addframe(dist_highlight_movie,color_dist_label);
        
        for j=1:max(dist_label(:))
            if (i < cali_time)
                pixels_at_dists_pre(j) = {[[pixels_at_dists_pre{j}]; this_image_no_scale(dist_label == j)]};
            else
                pixels_at_dists_post(j) = {[[pixels_at_dists_post{j}]; this_image_no_scale(dist_label == j)]};
            end
        end
        if (mod(i,10) == 0)
            send_message(['STATUS: Done with frame ',num2str(i), '/', num2str(image_num), ' in ', image_files(k).name]);
        end
    end
        
    cell_highlight_movie = close(cell_highlight_movie);
    dist_highlight_movie = close(dist_highlight_movie);
    
end

send_message(['STATUS: done examining image data']);

while (isempty(pixels_at_dists_pre{end}))
    pixels_at_dists_pre = pixels_at_dists_pre(1:(end - 1));
end

while (isempty(pixels_at_dists_post{end}))
    pixels_at_dists_post = pixels_at_dists_post(1:(end - 1));
end

save(fullfile(fileparts(I_file),'pixel_values.mat'),'pixels_at_dists_pre','pixels_at_dists_post','dist_means');

end