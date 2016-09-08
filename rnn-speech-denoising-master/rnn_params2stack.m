function [ stack, W_t ] = rnn_params2stack( params, eI )
%RNN_PARAMS2STACK Convert single parameter vector to stack weight structure
%   Extracts stack based on architecture information in eI

stack = cell(1, numel(eI.layerSizes));
prevSize = eI.inputDim;
p = 1;

%% default weight tying to false
if ~isfield(eI, 'tieWeights')
    eI.tieWeights = 0;
end;

if eI.tieWeights
    assert(mod(numel(eI.layerSizes),2) == 0, ...
        'Tied weights must have even layersize length');
end;
%% default short circuits to false
if ~isfield(eI, 'shortCircuit')
    eI.shortCircuit = 0;
end;    
%% pull weights from vector
for l = 1 : numel(eI.layerSizes)
    stack{l}=struct;
    % index parameters from large vector and reshape
    curSize = eI.layerSizes(l);
    % weight matrix
    wSize = curSize * prevSize;
    if ~eI.tieWeights || l <= numel(eI.layerSizes)/2 ...
            || l == numel(eI.layerSizes)
        % this is a weight layer with stored weights
        stack{l}.W = reshape(params(p:p+wSize-1), curSize, prevSize);
        p = p+wSize;
    else
        % tied weights layer with duplicate weights
        lEnc = numel(eI.layerSizes) - l + 1;
        stack{l}.W = stack{lEnc}.W';
    end;
    % bias vector. even tied layers have this distinct
    stack{l}.b = params(p:p+curSize-1);
    % populate the tied weights layer
    %         if l > 1
    %             lDec = l-1 + floor(numel(eI.layerSizes)/2);
    %             assert(layerSizes(l)==layerSizes(lDec), ...
    %                 'layzersizes not compatible with tied weights');
    %             stack{lDec}=struct;
    %             stack{lDec}.W = stack{l}.W';
    %             stack{lDec}.b = stack{l-1}.b;
    %         end;
    p = p+curSize;
    prevSize = curSize;
end


%% extract recurrent matrix if it existsa
W_t = [];
if eI.temporalLayer
    wSize = eI.layerSizes(eI.temporalLayer) ^ 2;
    W_t = reshape(params(p:p+wSize-1),eI.layerSizes(eI.temporalLayer),...
        eI.layerSizes(eI.temporalLayer));
    p = p+wSize;
end
%% extract short circuit layer
if eI.shortCircuit
    wSize = eI.inputDim * eI.layerSizes(end);
    stack{end}.W_ss = reshape(params(p:p+wSize-1), eI.layerSizes(end),...
        eI.inputDim);
    p = p+wSize;
end;
%% check all parameters accounted for
assert(p-1 == numel(params));

