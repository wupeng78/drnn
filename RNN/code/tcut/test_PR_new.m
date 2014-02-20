% test PR
vis = 1;

addpath ../
load ../../output/iccv09-1_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_good.mat
load ../../data/iccv09-allData-eval.mat
run('~/working/deep/vlfeat-0.9.16/toolbox/vl_setup.m');

% compute all parse trees
tree_file = '../../output/iccv09-allTrees-eval.mat';
if ~exist('allTrees','var')
    if exist(tree_file,'file')
        load(tree_file); 
    else
        allTrees = cell(1,length(allData));
        for i = 1:length(allData)
            if length(allData{i}.segLabels)~=size(allData{i}.feat2,1)
                disp(['Image ' num2str(i) ' has faulty data, skipping!'])
                continue
            end
            topCorr=0;
            imgTreeTop = parseImage(topCorr,Wbot,W,Wout,Wcat,allData{i}.adj, ...
                allData{i}.feat2,allData{i}.segLabels,params);
            allTrees{i} = imgTreeTop;
        end
        save('../../output/iccv09-allTrees-eval.mat', 'allTrees');
    end
end

theta_plus = MLE_theta(allData,8);

% for each image
PR_peaks = zeros(1,length(allData));
for i = 4:length(allData)
    
    % get which p_connect will be used
    [~,~,~,~,q_max_diff,q_max_diff_ind] = tree_cut_new(allData{i}, allTrees{i}, theta_plus, 8, -1);
    
    p_samples = unique(q_max_diff);
    %p_samples = 1./(9 - exp(p_samples));
    p_samples = 1./(1+8./exp(p_samples));
    p_samples = [0, p_samples, 0.5, 1];
    p_samples = sort(p_samples(p_samples >= 0));
    p_samples = unique(p_samples);
    %p_samples = 0:0.05:1.0;
    
    [PRs,~,nCuts] = evalSegPerImg(@tree_cut_new, allData{i}, allTrees{i}, theta_plus, 8, p_samples,1);
    %[peak,loc] = max(PRs);
    [peak,loc] = fullmax(PRs);
    [mnc,mmi] = min(nCuts(loc));
    PR_peaks(i) = peak(mmi);

    fprintf('>>>>>> %d best PR value = %f at %f\n', i, peak(mmi), p_samples(loc(mmi)));
    fprintf('------ forest: number of subtrees = %d\n', mnc);
    if (vis)
        pause
    end
end