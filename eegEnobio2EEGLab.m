function file_eeglab = eegEnobio2EEGLab(file_easy, file_info, path_eeglab)
% converts enobio .easy/.info data into eeglab .set/.fdt format. This can
% then be loaded into fieldtrip. 
%
% path_easy     - path to an enobio .easy file. 
%
% path_info     - path to an enobio .info file
%
% path_eeglab   - output path (folder) to save eeglab data in. Filename
%                 will be the same as the .easy/.info files

% check input args, filenames

    % check input paths
    if ~exist(file_easy, 'file')
        error('.easy file not found.')
    end
    if ~exist(file_info, 'file')
        error('.info file not found.')
    end
    
    % check output path
    if ~exist(path_eeglab, 'dir')
        error('Output path [%s] does not exist.', path_eeglab)
    end
    
% load into eeglab

    % load 
    eeg = pop_easy(file_easy);

    % look up channel locations based on 10-10 names
    eeg = pop_chanedit(eeg, 'lookup', 'standard-10-5-cap385.elp');
    
% save

    % extract filename from input path
    [~, filename, ~] = fileparts(file_easy);
    
    % make output filename
    file_eeglab = fullfile(path_eeglab, sprintf('%s.set', filename));

    % save 
    pop_saveset(eeg, file_eeglab);
    
end