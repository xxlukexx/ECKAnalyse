% files = recdir('/Volumes/Projects/Phase 2/saliency/social');
% idx = cellfun(@(x) instr(x, '.png'), files);
% files(~idx) = [];
% cellfun(@delete, files(idx))

files = recdir('/Volumes/Projects/Phase 2/saliency/social');
idx = cellfun(@(x) instr(x, '.avi'), files);
files(~idx) = [];

[pth, fil, ext] = cellfun(@fileparts, files, 'uniform', false);

for f = 13:length(files)
    parts = strsplit(pth{f}, filesep);
    newName = fullfile(pth{f}, sprintf('%s%s', parts{end}, ext{f}));
    movefile(files{f}, newName)
end