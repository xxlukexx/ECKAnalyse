function [validLeftProp, validRightProp, validAvgProp, avgData] =...
    etAverageEyeData(leftEyeData, rightEyeData)

% takes two columns of data, one for left eye and one for the right eyes.
% Averages these columns, and returns data validity statistics for both
% eyes, and for the average. 
%
% Note that this works with gaze data, pupilometry - basically anything
% with data in a column for each eye, where -1 means invalid data

% -1 is our marker of invalid data - can be changed
inv = -1;

% data validity
[~, validLeftProp, validLeftIdx] =...
    etCountValidSamples(leftEyeData);
[~, validRightProp, validRightIdx] =...
    etCountValidSamples(rightEyeData);

% average, using best combination of data
avgData = repmat(-1, size(leftEyeData, 1), 1);

% where both eyes are available, take average
bothEyes = validLeftIdx & validRightIdx;
avgData(bothEyes) = (leftEyeData(bothEyes) + rightEyeData(bothEyes)) / 2;

% where only left or only right is available, use this
leftOnly = validLeftIdx & ~validRightIdx;
avgData(leftOnly) = leftEyeData(leftOnly);
rightOnly = validRightIdx & ~validLeftIdx;
avgData(rightOnly) = rightEyeData(rightOnly);

% stats on new average
[~, validAvgProp, ~] = etCountValidSamples(avgData);
end
