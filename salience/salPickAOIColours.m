function def = salPickAOIColours(img, def)

    if ~exist('def', 'var') || isempty(def)
        def = {};
    end
    
    if ischar(img)
        if ~exist(img, 'file'), error('File not found.'), end
        try
            img = imread(img);
        catch ERR
            error('Could not load image.')
        end
    end
               
    % get AOI name and feature nampwd
    aoiName = input('Enter AOI name (e.g. "FACE"): >', 's');
    aoiFeatureName = input('Enter feature name (e.g. "aoi_face"): >', 's');

    % get number of colours
    numColHappy = false;
    while ~numColHappy
        aoiNumCols =...
            str2double(input('How many colours in this AOI?', 's'));
        numColHappy = ~isempty(aoiNumCols);
    end
    
    fig = figure('Name', 'Pick Colour', 'menubar', 'none');
    imshow(img);
    
    [x, y] = ginput(aoiNumCols);
    
    defCol = cell(1, aoiNumCols);
    mask = false(size(img, 1), size(img, 2));
    for c = 1:aoiNumCols
        defCol{c} = shiftdim(img(round(y(c)), round(x(c)), :), 1);
        mask = mask | roiRGB(img, defCol{c});
    end
    
    def{end + 1, 1} = aoiName;
    def{end, 2} = aoiFeatureName;
    def{end, 3} = defCol;
    
    test = img;
    mask = repmat(mask, 1, 1, 3);
    test(~mask) = 0;
    imshow(test);
    
end