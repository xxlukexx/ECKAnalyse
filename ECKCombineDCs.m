function dcOut = ECKCombineDCs(varargin)

    % takes all the ECKData instances in dc2 and adds them to dc1. Note
    % that this does not combine any data outside the ECKData collection.
    % For example, the ExtraData and Audit structs are NOT combined (or
    % touched at all - whatever was in dc1 is returned, anything in dc2
    % apart from the ECKData collection is dumped).
    
    if ~any(cellfun(@(x) isa(x, 'ECKDataContainer'), varargin))
        error('All input arguments must be ECKDataConatiners.')
    end
    
    dcOut = varargin{1};
    
    for cont = 2:length(varargin)
        for d = 1:varargin{cont}.NumData
            dcOut.AddData(varargin{cont}.Data{d});
        end
    end

end