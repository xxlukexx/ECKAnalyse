function etQCReport(data, reportPath)

    % etQCReport Prepare a PDF report summarising data quality for an eye
    % tracking session.
    %
    %   Produces one summary page for the entire session, and two detail pages
    %   for each supported task. Detail pages show raw gaze traces and
    %   contain (1) a selection of four trials from the beginning, middle and 
    %   end of the session; and (2) all trials of a task, segmented and then 
    %   pasted together. 
    %
    %   ETQCREPORT(data) runs the report and saves the PDF files in a 'QC'
    %   folder within the session folder of the dataset. 'data' can  either
    %       - an ECKData instance
    %       - an ECKDataContainer instance
    %       - the path to a session folder
    %       - the path to multiple sessions folders
    %
    %   ETQCREPORT(data, reportPath) runs the report and saves it in the
    %   folder specified by reportPath. 

    %% setup
    
    wb = waitbar(0, 'Checking data...');

    % if no path was supplied, prompt for one
    if ~exist('data', 'var')
        dataPath = uigetdir(pwd, 'Select path to data');
        if isnumeric(dataPath) && dataPath == 0
            errordlg('Invalid path')
            return
        end
    end

    % if a path was supplied (as opposed to a DC), create a DC and load 
    if exist('data', 'var') && ischar(data)
        dataPath = data;
    end
    
    if exist('dataPath', 'var')
        if ~exist(dataPath, 'dir')
            errordlg('Path not found.')
            return
        else
            dc = ECKDataContainer(dataPath);
        end
    else
        dc = checkDataIn(data);
    end
    
    % if no data was found, throw an error
    if dc.NumData == 0
        errordlg('No data found.')
        return
    end
    
    % check output path, if not supplied then the report will be saved into
    % each session folder (note this by setting reportPath to empty)
    if exist('reportPath', 'var') && ~isempty(reportPath)
        if ~exist(reportPath, 'dir')
            [mkSuc, mkMessage] = mkdir(reportPath);
            if ~mkSuc
                errordlg(sprintf(...
                    ['Report path (%s) not found. Tried to create it but',...
                    ' returned error (%s)'], reportPath, mkMessage));
            end
        end
        reportPathPresent = true;
    else
        reportPathPresent = false;
    end
    
    % set up figure for plotting
    axisCol = [.5, .5, .5];
    defAlpha = .3;
    edgeRed = [.6, .1, .1];
    lineWidth = 2;
    
    % load trial gaze data
    wb = waitbar(0, wb, 'Segmenting trial gaze data...');
    dc = etLoadTrialGazeData(dc);
    
    %% one page summary
    
    % loop through data and get quality
    for d = 1:dc.NumData
        
        % if necessary, get session folder for output path
        if ~reportPathPresent
            reportPath = [dc.Data{d}.SessionPath, filesep, 'QC'];
            if ~exist(reportPath, 'dir')
                mkdir(reportPath);
            end
        end
        
        % extract PID, convert to char if necessary
        pid = dc.Data{d}.ParticipantID;
        if isnumeric(pid), pid = num2str(pid); end        
        
        % extract timepoint, convert to char if necessary
        tp = dc.Data{d}.TimePoint;
        if isnumeric(tp), tp = num2str(tp); end
        
        % extract battery, convert to char if necessary
        bat = dc.Data{d}.Battery;
        if isnumeric(bat), bat = num2str(bat); end        
        
        % build output filename
        fileID = [reportPath, filesep, 'QC_', pid, '_', bat, '_', tp];
    
        wb = waitbar(d / dc.NumData, wb, sprintf(...
            'Session %d of %d (%s)...\n', d, dc.NumData, pid));  
        
        % set up figure
        close all
        a4 = [0, 0, 21, 29.7];
        a4Margin = [a4(1) - 1, a4(2) - 1.5, a4(3) + 1, a4(4) + 2.5];
        a4Inside = [a4(1) + 1, a4(2) + 1, a4(3) - 1, a4(4) - 1];
        p1 = figure('MenuBar', 'none', 'visible', 'off');
        orient tall
        set(p1, 'Units', 'normalized')
    
        % get data quality
        qual = dc.Data{d}.Quality;
        
        % get some variables
        time = qual.TimeVector;
        
        % eye val
        eyeVal = qual.EyeValidity;
        eyeLabels = {'No eyes', 'One eye', 'Both eyes'};
        sp = subplot(6, 3, 3);
        if size(eyeVal, 1) == length(eyeLabels)
            pie(eyeVal(:, 2), eyeLabels);
        else
            pie(eyeVal(:, 2));
        end
        title('Eye validity', 'fontweight', 'bold')
    
        % eye val time series
        sp = subplot(6, 3, 4:5);
        if ~isempty(qual.EyeValidityTimeSeries.Time) &&...
                ~isempty(qual.EyeValidityTimeSeries.Data)
            
            arEyeVal = area(qual.EyeValidityTimeSeries.Time,...
                qual.EyeValidityTimeSeries.Data);
            set(gca, 'fontsize', 8);
            title('Valid data over time', 'fontweight', 'bold')
        
        end
        
        % sampling frequency
        sp = subplot(6, 3, 17);
        plot(time(1:length(qual.SampleFrequencyTimeSeries)),...
            qual.SampleFrequencyTimeSeries, 'r')
        xlabel('Duration (s)')
        ylabel('Frequency (Hz)')
        set(gca, 'fontsize', 8);
        title('Sampling frequency: series', 'fontweight', 'bold')
        
        sp = subplot(6, 3, 18);
        hist(qual.SampleFrequencyTimeSeries);
        set(gca, 'fontsize', 8);
        h = findobj(gca,'Type','patch');
        set(h,'FaceColor','r')
        xlabel('Sampling Frequency (Hz)')
        set(gca, 'ytick', 0);
        set(gca, 'yticklabel', []);
        title('Sampling frequency: histogram', 'fontweight', 'bold')        

        % gap histogram
        sp = subplot(6, 3, 16);
        if ~isempty(qual.GapHist.BinsTime) &&...
                ~isempty(qual.GapHist.HistTime)
 
            b = bar(qual.GapHist.BinsTime / 1000, qual.GapHist.HistTime,...
                'histc');
            set(gca, 'fontsize', 8);
            ylabel('Total Duration (s)')
            xlabel('Fragment Duration (s)')
            title('Distribution of lost fragments', 'fontweight', 'bold')
            
        end
        
        % trials by tasks
        sp = subplot(6, 3, 7:15);
        axis off
        set(sp, 'Units', 'normalized');
        spRect = get(sp, 'Position');
        [comp, compProp] = etCompletenessSummary(dc.Data{d});
        if ~isempty(comp) && ~isempty(compProp)
            compProp = compProp(2:end, :);
            flagComp = all(cell2mat(compProp(:, 2)) == 1);
            compProp(:, 2) = cellstr([num2str(cell2mat(compProp(:, 2)) * 100),...
                repmat('%', [size(compProp, 1), 1])]);
            if ~isempty(compProp)
                strText = prepAnnotation(compProp(2:end, :), {'Task', 'Prop. complete'});        
                if flagComp, trCompStr = '<strong>*** COMPLETE ***</strong>'; else trCompStr = '*** INCOMPLETE ***'; end
                strText = [strText; ' '; ' '; trCompStr];
            end
        end
        if ~exist('strText', 'var') || isempty(strText)
            strText = {'MISSING TASK INFORMATION'};
        end
    
        % post-hoc calib
        [phHdr, phData] = etCollateTask(dc.Data{d}, 'posthoc_calib');
        if ~isempty(phData)
            pointX = cell2mat(phData(:, 8));
            pointY = cell2mat(phData(:, 9));
            gazeX = cell2mat(phData(:, 6));
            gazeY = cell2mat(phData(:, 7));
            gazeX(gazeX < 0) = nan;
            gazeY(gazeY < 0) = nan;
            subplot(6, 3, 6)
            hold on
            scatter(pointX, pointY, 40, 'MarkerEdgeColor', 'b',...
                          'MarkerFaceColor', 'c',...
                          'LineWidth', 1.5)
            scatter(gazeX, gazeY, '.r')
            set(gca, 'fontsize', 8);
            hold off
            title('Post-hoc calibration', 'fontweight', 'bold')
        else
            subplot(6, 3, 18)
            annotation('TextBox', [0, 0, 1, 1], 'String', 'No post-hoc calib data.');
        end

        % duration
        dur = qual.DurationS;
        secsInDay = 60 * 60 * 24;
        durProp = dur / secsInDay;

        % other details
        strText = [...
            'Participant ID:            ', pid;...
            'Timepoint / schedule:      ', tp;...
            'Battery:                   ', bat;...
            'Duration:                  ', datestr(durProp, 'HH:MM:SS');...
            ' ';...
            ' ';...
            strText;...
            ' ';...
            'Session path:              ', dc.Data{d}.SessionPath;...
            ];    

        % valid data by task
        if isfield(dc.Data{d}.Log, 'ValidSamples')
            subplot(6, 3, 1:2)
            taskTrialVal = dc.Data{d}.Log.ValidSamples;         % valid samples per task/trial
            taskNames = dc.Data{d}.Log.FunName;                 % task names
            missing = cellfun(@isempty, taskTrialVal);          % tasks with missing data
            taskTrialVal = taskTrialVal(~missing);              % filter out missing 
            taskNames = taskNames(~missing);                    % filter out missing
            taskNames = strrep(taskNames, '_trial', '');        % remove '_trial' from names

            if ~isempty(taskTrialVal)                           % skip if not valid tasks
                taskVal = cellfun(@mean, taskTrialVal);         % collapse across trial   
                bar(taskVal);
                set(gca,'xtick', 1:numel(taskNames), 'xticklabel', taskNames)
                title('Valid data by task')
            end
        end
               
        % set font to arial
        set(gca, 'FontName', 'Arial',  'FontSize', 8)
        set(findall(gcf,'type','text'),'FontName', 'Arial', 'FontSize', 8)
        colormap('parula')

        % draw task/trial info
        annotation(...
            'textbox', spRect,...
            'FontName', 'Courier',...
            'FontSize', 8,...
            'Interpreter', 'none',...
            'String',   strText)

        % title
        annotation(...
            'textbox', [0, .975, 1, .025],...
            'String', 'Eye Tracking Data Quality Report: session summary',...
            'FontName', 'Arial',...
            'FontSize', 8,...
            'LineStyle', 'none',...
            'FontWeight', 'Bold');
        
        % save
        fileIDCheck = find(double(fileID) == 10);
        if ~isempty(fileIDCheck)
            fileID = [fileID(1:a - 1), fileID(a + 1:end)];
        end
        print('-dpdf', [fileID, '_session.pdf'])
    
        %% task by task detail

        hideEvents = {'ADDAOI', 'FRAME', 'IMG_CYCLE', 'NSCONT_FIXATION_OFFSET',...
            'NSCONT_REWARD_ONSET', 'NSCONT_REWARD_OFFSET',...
            'NSCONT_TRIAL_OFFSET', 'NSCONT_REWARD_GAZE'};

        % get trials with available gaze data
        if isfield(dc.Data{d}.Log, 'Gaze')
            
            availGaze = find(~cellfun(@isempty, dc.Data{d}.Log.Gaze));
            for curTask = 1:length(availGaze)

                % load task name and log data
                tName = dc.Data{d}.Log.FunName{availGaze(curTask)};
                tData = dc.Data{d}.Log.Data{availGaze(curTask)};

                % filter trial data to remove 'N/A' in first column
                tData = tData(~strcmpi(tData(:, 1), 'N/A'), :);

                numTrials = size(tData, 1);
                maxTrials = 4;

                if numTrials <= maxTrials
                    trialIdx = 1:numTrials;
                else
                    trialStep = ceil(numTrials / maxTrials);
                    trialIdx = 1:trialStep:numTrials;
                end

                % set up page
                clf
                orient tall

                spCount = 1;
                curTr = 1;
                while curTr <= length(trialIdx)

                    trialNo = LeadingString('00', trialIdx(curTr));

                    % get gaze
                    trGaze = dc.Data{d}.Log.Gaze{availGaze(curTask)}{trialIdx(curTr)};
                    trTime = dc.Data{d}.Log.Time{availGaze(curTask)}{trialIdx(curTr)};
                    trEvents = dc.Data{d}.Log.Events{availGaze(curTask)}{trialIdx(curTr)};  
                    trTitle = [tName, '_', trialNo];
                    drawEvents = true;
                    sp = subplot(8, 2, spCount:spCount + 1, 'Color',[1, 1, 1]);

                    if ~isempty(trGaze)
                        % filter out events that we don't want to see

                        % get x + y
                        [~, ~, ~, gx] = etAverageEyeData(trGaze(:, 7), trGaze(:, 20));
                        [~, ~, ~, gy] = etAverageEyeData(trGaze(:, 8), trGaze(:, 21));
                        [~, ~, ~, p] = etAverageEyeData(trGaze(:, 12), trGaze(:, 25));

                        gx(gx < 0 | gx > 1) = nan;
                        gy(gy < 0 | gy > 1) = nan;
                        p(p < 0) = nan;
                        p = (p - min(p)) / (max(p) - min(p));

                        i = (1:length(gx)) / qual.SampleFrequencyMean;

                        hold on
                        ph = plot(i, gx, i, gy, i, p);
                        set(gca, 'xColor', axisCol);
                        set(gca, 'yColor', axisCol);
                        set(gca, 'fontsize', 8);

                        figPar = get(ph, 'parent');
                        figBounds = get(figPar{1}, 'Position');
                        text(-.075, 0, trTitle,...
                            'units', 'normalized',...
                            'Rotation', 90,...
                            'FontSize', 8,...
                            'Interpreter', 'none',...
                            'HorizontalAlignment', 'center',...
                            'BackgroundColor', [.86, .90, .95],...
                            'VerticalAlignment', 'middle')

                        % draw events
                        if ~isempty(trEvents) && ~size(trEvents, 1) == 1 && drawEvents
                            % adjust event time to trial-relative
                            evRelTime = double(cell2mat(trEvents(:, 2))) / 1000000;
                            evRelTime = evRelTime - evRelTime(1);
                            textY = 0.1;
                            evI = nan(size(i));
                            for curE = 1:length(evRelTime)
                                ev = trEvents{curE, 3};
                                if iscell(ev)
                                    ev = ev{1};
                                end
                                if all(cellfun(@isempty, cellfun(@(x) strfind(ev, x),...
                                        hideEvents, 'UniformOutput', false)))
                                    h = text(evRelTime(curE), textY, ev,...
                                        'interpreter', 'none',...
                                        'fontsize', 7);
                                    evI(find(evRelTime(curE) > i, 1, 'last')) = 1;
                                    textBounds = get(h, 'extent');
                                    textY = textY + (textBounds(4) / 2);
                                    if textBounds(2) > (textBounds(4)), textY = 0.1; end
                                end
                            end

                            if ~any(isnan(evI)), bar(i, evI, 'r'); end
                        end
                        hold off

                        % plot velocity
                        spCount = spCount + 2;
                        subplot(8, 2, spCount:spCount + 1);
                        vel = etVelocity(gx, gy);
                        ax = plot(i(1:end), vel);
                        set(gca, 'xColor', axisCol);
                        set(gca, 'yColor', axisCol);
                        set(gca, 'fontsize', 8);
                        spCount = spCount + 2;

                    end

                    curTr = curTr + 1;
                end

                % title
                annotation(...
                    'textbox', [0, .975, 1, .025],...
                    'String', ['Eye Tracking Data Quality Report: Task summary: ', tName, ' FOUR TRIAL SAMPLE'],...
                    'LineStyle', 'none',...
                    'Interpreter', 'none',...
                    'FontWeight', 'Bold');

                % save PDF
                fname = [fileID, '_task', LeadingString('00', curTask), '_', tName,...
                    '_TRIALS', '.pdf'];
                print('-dpdf', fname);

                 %% WHOLE TRIAL DATA ON LANDSCAPE PAGE

                % close current page, open landscape page
                clf
                orient landscape

                % get all gaze for this trial
                trGaze = cell2mat(dc.Data{d}.Log.Gaze{availGaze(curTask)});
                trTime = cell2mat(dc.Data{d}.Log.Time{availGaze(curTask)});
                trTitle = [tName, ' - All data'];

                % split trial into three sections (one for each row)
                numSecs = 3;
                numSamps = size(trGaze, 1);
                on(1) = 1;
                off(1) = floor(numSamps / 3);
                on(2) = off(1) + 1;
                off(2) = floor(2 * (numSamps / 3));
                on(3) = off(2) + 1;
                off(3) = numSamps;
                i = (1:length(trTime)) / qual.SampleFrequencyMean;

                spCount = 1;

                for curSec = 1:numSecs

                    % plot
                    sp = subplot(6, 1, spCount);

                    % get x + y
                    [~, ~, ~, gx] =...
                        etAverageEyeData(trGaze(on(curSec):off(curSec), 7),...
                        trGaze(on(curSec):off(curSec), 20));
                    [~, ~, ~, gy] =...
                        etAverageEyeData(trGaze(on(curSec):off(curSec), 8),...
                        trGaze(on(curSec):off(curSec), 21));
                    [~, ~, ~, p] =...
                        etAverageEyeData(trGaze(on(curSec):off(curSec), 12),...
                        trGaze(on(curSec):off(curSec), 25));

                    gx(gx < 0 | gx > 1) = nan;
                    gy(gy < 0 | gy > 1) = nan;
                    p(p < 0) = nan;
                    p = (p - min(p)) / (max(p) - min(p));

                    hold on
                    ph = plot(...
                        i(on(curSec):off(curSec)),...
                        gx, i(on(curSec):off(curSec)),...
                        gy, i(on(curSec):off(curSec)), p);

                    set(gca, 'xColor', axisCol);
                    set(gca, 'yColor', axisCol);
                    set(gca, 'fontsize', 8);

                    % plot trial onset/offset markers
                    trI = nan(size(i(on(curSec):off(curSec))));
                    if ~isempty(trI)
                        trTimeIdx = ~cellfun(@isempty, dc.Data{d}.Log.Time...
                            {availGaze(curTask)});
                        trTimeFilt = dc.Data{d}.Log.Time{availGaze(curTask)}(trTimeIdx);
                        trOnsets = double(cell2mat(cellfun(@(x) x(1, 1), trTimeFilt,...
                            'UniformOutput', false)));
                        trTimes = cell2mat(arrayfun(@(x)...
                            find(double(trTime(on(1):off(1)))' - x > 0, 1, 'first'),...
                            trOnsets, 'UniformOutput', false));
                        trI(trTimes) = 1;
                        if ~any(isnan(trI)), bar(i(on(curSec):off(curSec)), trI); end
                    end

                    % title
                    trTitle = [tName, ' - ', num2str(curSec), '/', num2str(numSecs)];
                    text(-.075, 0, trTitle,...
                            'units', 'normalized',...
                            'Rotation', 90,...
                            'FontSize', 8,...
                            'Interpreter', 'none',...
                            'HorizontalAlignment', 'center',...
                            'BackgroundColor', [.86, .90, .95],...
                            'VerticalAlignment', 'middle')


                    % plot vel
                    spCount = spCount + 1;
                    subplot(6, 1, spCount);
                    vel = etVelocity(gx, gy);
                    if ~all(isempty(vel)) && ~all(vel == 0)
                        plot(i(on(curSec):off(curSec)), vel)
                        set(gca, 'xColor', axisCol);
                        set(gca, 'yColor', axisCol);
                        set(gca, 'fontsize', 8);
                    end
                    spCount = spCount + 1;    

                end

                % title
                annotation(...
                    'textbox', [0, .975, 1, .025],...
                    'String', ['Eye Tracking Data Quality Report: Task summary: ', tName, ' ALL TRIALS'],...
                    'LineStyle', 'none',...
                    'Interpreter', 'none',...
                    'FontWeight', 'Bold');

                % save PDF
                fname = [fileID, '_task', LeadingString('00', curTask), '_', tName,...
                    '_ALL', '.pdf'];
%                 print('-dpdf', fname);
                saveas(gcf, fname, 'pdf');

                st.Status = sprintf('done.\n');

            end

        end
        
    end
    
    close(wb)
    close all
    
end
        
    
