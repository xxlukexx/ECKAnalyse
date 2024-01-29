function heatmaps = ECKHeatMap(data, type, screenRes, screenSize, blurRadius)
    
    %% SETUP

    % screenRes =   [x, y] in pixels (e.g. [1920, 1080])
    %
    % type =        {'DataWise' | 'SampleWise'}
    %
    %               'DataWise' - make separate heatmap for each dataset in
    %               the DC (summarises gaze over trials for each
    %               participant)
    %               'SampleWise' - make separate heatmap for each sample,
    %               but include all participants in the heatmap (summarises
    %               gaze over time, by groups of participants). Filter the
    %               DC before use to make heatmaps of a subsample. 
    %
    % screenSize =  [w, h] in any unit you like. 
    %
    % blurRadius =  r in the same units as screenSize

    % check data
    dc = checkDataIn(data);
    
    % check input vars, if not assume reasonable defaults
    if ~exist('type', 'var') || isempty(type)
        type = 'DataWise';
    end
    
    if ~strcmpi(type, 'datawise') && ~strcmpi(type, 'samplewise')
        error('Invalid type specified')
    end
        
    if ~exist('screenRes', 'var') || isempty(screenRes)
        screenRes = [1920, 1080];
    end
    
    if ~exist('screenSize', 'var') || isempty(screenSize)
        % default assumes 23" diagonal 16:9 monitor (e.g. TX-300 screen).
        % Expressed in degrees of visual angle
        screenSize = [45.984, 26.848];
    end
    
    if ~exist('blurRadius', 'var') || isempty(blurRadius)
        blurRadius = 2;
    end
    
    % get image size vars
    xw = screenRes(1) / screenSize(1);
    yw = screenRes(2) / screenSize(2);
    pointRad = round(mean([xw, yw]) * blurRadius);
    hDisk = fspecial('disk', pointRad);
    hGauss = fspecial('gaussian', round(pointRad * 1.5), pointRad);
    
    % preallocate output array of heatmaps
    heatmaps = zeros(screenRes(1), screenRes(2), dc.NumData);
    
    %% GET DATA
    switch lower(type)
        case 'datawise'
            
            % cell array to store x, y gaze data for each dataset
            gaze = cell(dc.NumData, 1);
    
            for d = 1:dc.NumData
                
                % read data, filter, average
                mb = dc.Data{d}.MainBuffer;
                mb = etFilterGazeOnscreen(mb);
                [x, y, ~] = etAverageEyeBuffer(mb);
                nanIdx = isnan(x) | isnan(y);
                x(nanIdx) = [];
                y(nanIdx) = [];
                gaze{d} = [x, y];
                
            end
            
        case 'samplewise'
            
            gx = cell(dc.NumData, 1);
            gy = cell(dc.NumData, 1);
            gaze = [];
            
            % find number of samples for each dataset
            numSamp = zeros(dc.NumData, 1);
            for d = 1:dc.NumData
                [gx{d}, gy{d}, ~] = etAverageEyeBuffer(dc.Data{d}.MainBuffer);
                numSamp(d) = size(gx{d}, 1);
            end
            
            if ~isempty(gx) && ~isempty(gy)
                
                % find min number of samples and standardise on that
                maxSamp = max(numSamp);

                % cell array to store x, y gaze data for each dataset
                gaze = cell(maxSamp, 1);            

                % loop through and read data by sample          
                parfor s = 1:maxSamp

                    gaze{s} = nan(dc.NumData, 2);

                    for d = 1:dc.NumData

                        if numSamp(d) >= s

                            x = gx{d}(s);
                            y = gy{d}(s);

                            % filter gaze on screen
                            if x < 0 || x > 1 || y < 0 || y > 1
                                gaze{s}(d, 1) = nan;
                                gaze{s}(d, 2) = nan;
                            else
                                gaze{s}(d, 1) = gx{d}(s);
                                gaze{s}(d, 2) = gy{d}(s);
                            end

                        end

                    end

                end
                
            end
            
    end              
            
    %% MAKE HEATMAPS
    
    numData = length(gaze);
    bins = {0:1 / (screenRes(1) - 1):1, 0:1 / (screenRes(2) - 1):1};
    
    % attempt to use GPU if CUDA is available
    cudaAvail = true;
    try
        gpuDevice;
    catch ERR
        cudaAvail = false;
    end
    
    cudaAvail = false;
    
    % loop thorugh data and make heatmaps
    tic
    parfor d = 1:numData
        
        x = gaze{d}(:, 1);
        y = gaze{d}(:, 2);
        nanIdx = isnan(x) | isnan(y);
        x(nanIdx) = [];
        y(nanIdx) = [];
        
        if ~isempty(x) || ~isempty(y)
            
            % make 3D hist (aka heatmap)
            hm = hist3([x, y], bins);
            
%             if cudaAvail
%                 hm = gpuArray(heatmaps(:, :, d));
%             else
%                 hm = heatmaps(:, :, d);
%             end

            % disk filter to replicate foveal vision
            hm = imfilter(hm, hDisk);

            % gaussian blur
            hm = imfilter(hm, hGauss);

            % normalise
            heatmaps(:, :, d) = hm / max(max(hm));
            
%             if cudaAvail
%                 heatmaps(:, :, d) = gather(hm);
%             else 
%                 heatmaps(:, :, d) = hm;
%             end
        
        end
               
    end 
    
    if cudaAvail
        heatmaps = gather(heatmaps);
    end
%     fprintf('Processed heatmaps in %d seconds.\n', toc);

end