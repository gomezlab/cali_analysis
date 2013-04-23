function analyze_cali(data_dir)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'analyze_cali';

i_p.addRequired('data_dir',@(x)exist(x,'dir') == 7);

i_p.parse(data_dir);

send_message('STATUS: Processing Data...')

pixels_temp = load(fullfile(data_dir,'pixel_values.mat'));

pixels_at_dists_pre = pixels_temp.pixels_at_dists_pre;
pixels_at_dists_post = pixels_temp.pixels_at_dists_post;
dist_means = pixels_temp.dist_means;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

summary_pre = summarize_pixel_set(pixels_at_dists_pre);
send_message('STATUS: Done with processing pre-CALI data');

summary_post = summarize_pixel_set(pixels_at_dists_post);
send_message('STATUS: Done with processing post-CALI data');

summary_pre = [dist_means(1:length(summary_pre(1,:)));summary_pre];
summary_post = [dist_means(1:length(summary_post(1,:)));summary_post];

%Results output to CSV files
dlmwrite(fullfile(data_dir,'pre_cali_mean_intensities.csv'),summary_pre,'precision',10);
dlmwrite(fullfile(data_dir,'post_cali_mean_intensities.csv'),summary_post,'precision',10);

%Summary Figure
temp_fig = figure('Visible','off');
fig_hnd = errorbar(dist_means(1:length(summary_pre(1,:))), summary_pre(1,:), ...
    summary_pre(1,:)-summary_pre(2,:), summary_pre(1,:)-summary_pre(3,:));

xlabel('Mean Distance from Nearest Cell Edge (\mum)')
ylabel('Average Normalized Intensity (AU)')
hold on;
errorbar(dist_means(1:length(summary_post(1,:))), summary_post(1,:), ...
    summary_post(1,:)-summary_post(2,:), summary_post(1,:)-summary_post(3,:),'r');
legend('Pre-Cali','Post-Cali')
saveas(temp_fig,fullfile(data_dir,'cort_actin_intensity.pdf'))

send_message('STATUS: Done with processing extracted data');

end

function pixel_summary = summarize_pixel_set(pixels_set)

pixel_summary = zeros(5,length(pixels_set));

first_dist_mean = mean(double(pixels_set{1}))
for i=1:length(pixels_set)

	%normalize the pixel values to the first distance mean
	pixels_at_dist_norm = double(pixels_set{i})/first_dist_mean;
    pixel_summary(1,i) = mean(pixels_at_dist_norm);
	disp(mean(pixels_set{i})/first_dist_mean);
    
%     boot_temp = bootci(1000,{@mean,pixels_set{i}},'type','per');
    [h,pvalue,ci] = ttest(double(pixels_at_dist_norm));    
    
    pixel_summary(2,i) = ci(1);
    pixel_summary(3,i) = ci(2);
    pixel_summary(4,i) = std(double(pixels_at_dist_norm));
    pixel_summary(5,i) = length(pixels_at_dist_norm);
    
    send_message(['STATUS: Done with depth layer ', num2str(i), '/', num2str(length(pixels_set))]);
end

end
