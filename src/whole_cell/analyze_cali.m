function analyze_cali(data_dir)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'analyze_cali';

i_p.addRequired('data_dir',@(x)exist(x,'dir') == 7);

i_p.parse(data_dir);

% global status_text_hnd;
% set(status_text_hnd,'String','Processing Data...'); drawnow;

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