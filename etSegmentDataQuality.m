function dc = etSegmentDataQuality(dc)

    % loop through datasets
    for d = 1:dc.NumData
        
        % loop through segmentation jobs
        numJobs = length(dc.Data{d}.Segments);
        for j = 1:numJobs
            
            % loop through segments
            numSegs = length(dc.Data{d}.Segments(j).Segment);
            for s = 1:numSegs
                
                mb = dc.Data{d}.Segments(j).Segment(s).MainBuffer;

                % prop missing data
                oneEye = false(size(mb, 1), 1);
                noEyes = mb(:, 13) == 4 & mb(:, 26) == 4;
                twoEyes = mb(:, 13) == 0 & mb(:, 26) == 0;
                oneEye(~noEyes & ~twoEyes) = true;
                
                dc.Data{d}.Segments(j).Segment(s).NoEyes = noEyes;
                dc.Data{d}.Segments(j).Segment(s).PropNoEyes =...
                    sum(noEyes) / length(noEyes);
                dc.Data{d}.Segments(j).Segment(s).OneEye = oneEye;
                dc.Data{d}.Segments(j).Segment(s).PropOneEye =...
                    sum(oneEye) / length(oneEye);
                dc.Data{d}.Segments(j).Segment(s).TwoEyes = twoEyes;
                dc.Data{d}.Segments(j).Segment(s).PropTwoEyes =...
                    sum(twoEyes) / length(twoEyes);                
                
                % RMS
                mb = etAverageEyeBuffer(mb);
                mb = etFilterGazeOnscreen(mb);
                
                [rms_x, rms_y] =...
                    computeRMS(mb(~noEyes, 7), mb(~noEyes, 8), 1);
                
                dc.Data{d}.Segments(j).Segment(s).RMSx = rms_x;
                dc.Data{d}.Segments(j).Segment(s).RMSy = rms_y;
                
            end
            
        end
        
    end

end