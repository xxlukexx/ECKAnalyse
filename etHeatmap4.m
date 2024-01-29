function [hm, alpha] = etHeatmap4(x, y, res, outputRes, pxRes, cmap)

% takes x, y vectors and returns a heatmap as an image
%
% res       Resolution of 2D hist used to make heatmap. Smaller is better.
% outputRes Resolution of output heatmap. 
% pxRes     Optional resolution in same units as x, y. Useful if x and y
%           are in pixels 

    if ~exist('pxRes', 'var') || isempty(pxRes)
        mxx = round(max(x(:)));
        mxy = round(max(y(:)));
    else
        mxx = pxRes(1);
        mxy = pxRes(2);
    end
    
    if ~exist('cmap', 'var') || isempty(cmap)
        cmap = parula;
    end
    
    % remove NaNs
    miss = isnan(x) & isnan(y);
    x(miss) = [];
    y(miss) = [];
    
    hmParams = {linspace(0, mxy, res(2)), linspace(0, mxx, res(1))};
%     hm = hist3([y, x], hmParams);
    hm = histcounts2(y, x, hmParams{1}, hmParams{2}, 'Normalization', 'count');
    hm = imresize(hm, [outputRes(2), outputRes(1)], 'nearest');
%     hm = imgaussfilt(hm, .015 * outputRes(1));
    hm = imgaussfilt(hm, .040 * outputRes(1));
    hm = hm / max(hm(:));
    alpha = hm;
    hm = ind2rgb(round(255 * hm), cmap);
    hm = uint8(hm * 255);
    alpha = uint8(alpha * 255);
    
    
%     clf
%     sm = [.015, .020, .025, .030, .050, .075, .1];
%     nsp = numSubplots(length(sm));
%     for i = 1:length(sm)
%         tmp = imgaussfilt(hm, .015 * outputRes(1));
%         subplot(nsp(1), nsp(2), i)
%         imagesc(imgaussfilt(hm, sm(i) * outputRes(1)));
%     end
%     
%     
%     clf
%     
%     subplot(3, 2, 1)
%     hm = histcounts2(y, x, hmParams{1}, hmParams{2}, 'Normalization', 'count');
%     hm = imresize(hm, [outputRes(2), outputRes(1)], 'nearest');
%     hm = imgaussfilt(hm, .015 * outputRes(1));    
%     imagesc(hm);
%     
%     subplot(3, 2, 2)
%     hm = histcounts2(y, x, hmParams{1}, hmParams{2}, 'Normalization', 'countdensity');
%     hm = imresize(hm, [outputRes(2), outputRes(1)], 'nearest');
%     hm = imgaussfilt(hm, .015 * outputRes(1));    
%     imagesc(hm);
%     
%     subplot(3, 2, 3)
%     hm = histcounts2(y, x, hmParams{1}, hmParams{2}, 'Normalization', 'cumcount');
%     hm = imresize(hm, [outputRes(2), outputRes(1)], 'nearest');
%     hm = imgaussfilt(hm, .015 * outputRes(1));    
%     imagesc(hm);
%     
%     subplot(3, 2, 4)
%     hm = histcounts2(y, x, hmParams{1}, hmParams{2}, 'Normalization', 'probability');
%     hm = imresize(hm, [outputRes(2), outputRes(1)], 'nearest');
%     hm = imgaussfilt(hm, .015 * outputRes(1));    
%     imagesc(hm);
%     
%     subplot(3, 2, 5)
%     hm = histcounts2(y, x, hmParams{1}, hmParams{2}, 'Normalization', 'pdf');
%     hm = imresize(hm, [outputRes(2), outputRes(1)], 'nearest');
%     hm = imgaussfilt(hm, .015 * outputRes(1));    
%     imagesc(hm);
%     
%     subplot(3, 2, 6)
%     hm = histcounts2(y, x, hmParams{1}, hmParams{2}, 'Normalization', 'cdf');
%     hm = imresize(hm, [outputRes(2), outputRes(1)], 'nearest');
%     hm = imgaussfilt(hm, .015 * outputRes(1));    
%     imagesc(hm);    
    
    
end