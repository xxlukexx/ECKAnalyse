% get paths
[expPath, dataPath, gPath] = getExperimentsPath;

% add fieldtrip to path
ftPath = [expPath, filesep, 'face erp', filesep, 'fieldtrip-20170314'];
addpath(ftPath);
ft_defaults

clear all
eegp = ECKEEGTrialPlot;
load('/Users/luke/Documents/100693509718_FACE_ERP_EEG.preproc.mat')
eegp.Data = data;