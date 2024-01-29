function [dcOut] = ECKDuplicateDC(dcIn, reOrder)

    % check vars
    if ~exist('reOrder', 'var') || isempty(reOrder)
        reOrder = [];
    end
    
%     warning('Class based properties (e.g. log, tracker etc.) are still handle based!')

    if ~isa(dcIn, 'ECKDataContainer')
        error('Input argument must be an ECKDataContainer')
    end
    
    tmp = getByteStreamFromArray(dcIn);
    dcOut = getArrayFromByteStream(tmp);
    if ~isempty(reOrder) && dcOut.NumData > 0
        dcOut.Data = dcOut.Data(reOrder); 
    end
%     
%     for d = 1:length(dcIn.Data)
%         tmp = ECKDuplicateData(dcIn.Data{reOrder(d)});
% %         tmp = ECKData;
% %         tmp.Type                = dcIn.Data{d}.Type;
% %         tmp.ParticipantID       = dcIn.Data{d}.ParticipantID;
% %         tmp.TimePoint           = dcIn.Data{d}.TimePoint;
% %         tmp.Battery             = dcIn.Data{d}.Battery;
% %         tmp.SessionPath         = dcIn.Data{d}.SessionPath;
% %         tmp.CounterBalance      = dcIn.Data{d}.CounterBalance;
% %         tmp.Site                = dcIn.Data{d}.Site;
% %         tmp.Tracker             = dcIn.Data{d}.Tracker;
% %         tmp.Log                	= dcIn.Data{d}.Log;
% %         tmp.MainBuffer          = dcIn.Data{d}.MainBuffer;
% %         tmp.TimeBuffer          = dcIn.Data{d}.TimeBuffer;
% %         tmp.EventBuffer         = dcIn.Data{d}.EventBuffer;
%         dcOut.AddData(tmp);
%     end
    
    
end


