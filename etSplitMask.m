function maskOut = etSplitMask(maskIn, feat)

    cc = etAoIColourConstants;
    if ~isfield(cc, feat)
        error('No feature definition exists for %s.', feat)
    end
    
    cols = cc.(feat);
    numCols = size(cols, 1);
    
    maskOut = zeros(size(maskIn));
    w = size(maskOut, 2);
    h = size(maskOut, 1);

    % split into colour channels
    r = maskIn(:, :, 1);
    g = maskIn(:, :, 2);
    b = maskIn(:, :, 3);

    r_roi = roicolor(r, cols(240, 1), cols(end, 1));
    g_roi = roicolor(g, cols(240, 2), cols(end, 2));
    b_roi = roicolor(b, cols(240, 3), cols(end, 3));
%     r_roi = roicolor(r, cols(end, 1));
%     g_roi = roicolor(g, cols(end, 2));
%     b_roi = roicolor(b, cols(end, 3));
%     
    maskOut = r_roi & g_roi & b_roi;
    
    debug = true;
    if debug
        subplot(5, 2, 1:2)
        imshow(maskIn)
        title('Mask in')
        subplot(5, 2, 3)
        imshow(r)
        title('Red channel')
        subplot(5, 2, 4)
        imshow(r_roi)
        title('Red ROI filter')
        subplot(5, 2, 5)
        imshow(g)
        title('Green channel')
        subplot(5, 2, 6)
        imshow(g_roi)
        title('Green ROI filter')
        subplot(5, 2, 7)
        imshow(b)
        title('Blue channel')
        subplot(5, 2, 8)
        imshow(b_roi)
        title('Blue ROI filter')
        subplot(5, 2, 9:10)
        imshow(maskOut)
        title('Mask out')
    end

end