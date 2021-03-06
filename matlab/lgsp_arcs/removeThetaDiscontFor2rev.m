function thAdj = removeThetaDiscontFor2rev(thVals, img, isInner)
% Removes discontinuities in theta-values for points in a spiral that goes
%   for more than one theta-revolution.  
% Given points in the plane, we can assign theta-values in the range 
%   [0, 2pi].  If the points in the spiral go for more than one revolution, 
%   part of the spiral will have to cross the polar axis, creating
%   theta-value discontinuities there.  We fix this by adding or subtracting 
%    multiples of 2*pi where appropriate.  Thus, new theta-values are 
%   equivalent but some may be outside the range [0, 2*pi].  
% This is important for log-spiral fitting that measures error in r as a 
%   function of theta. This won't work if the inner or outer points cover 
%   the full [0,2*pi] range on their own!
% INPUTS:
%   thVals: theta-values for each point in the spiral
%   img: 
%   isInner: whether each point is in the inner part of the spiral (as
%       determined by idInnerOuterSpiral)
%   splitTh: the theta-value where the inner/outer points were split
% OUTPUTS:
%   thAdj: theta values that have an equivalent bearing but are adjusted to
%       avoid discontinuities

imgIdxs = find(img);

adjustedInner = false;
adjustedOuter = false;

thAdj = thVals;
if length(unique(isInner)) > 1
    thvInner = sort(thVals(isInner), 'ascend');
    gapInner = diff(thvInner);
    [maxGapInner, mgiIdx] = max(gapInner);
    zGapInner = thvInner(1) + 2*pi - thvInner(end);
    if zGapInner < maxGapInner
        % gap in inner points doesn't go through zero, some points will
        % need to be adjusted for continuity

        % determine which points are inner points on each side of the
        % theta=0 line, taking advantage of the fact that we know that the
        % gap in inner points does not go through zero
        maxInner1 = thvInner(mgiIdx);
        isInner1 = isInner & thVals <= maxInner1;
        minInner2 = thvInner(mgiIdx+1);
        isInner2 = isInner & thVals >= minInner2;
        
        imgOuter = false(size(img)); imgOuter(imgIdxs(~isInner)) = true;
        outerDists = bwdist(imgOuter);
        
        % the "innermost inner points" should be an "endpoint segment",
        % so adjusting these shouldn't introduce other discontinuities
        if min(outerDists(imgIdxs(isInner1))) > min(outerDists(imgIdxs(isInner2)))
            thAdj(isInner1) = thAdj(isInner1) + 2*pi;
        else
            thAdj(isInner2) = thAdj(isInner2) - 2*pi;
        end
        adjustedInner = true;
    end

    % do the same for outer points
    % TODO: maybe refactor the common code?
    thvOuter = sort(thVals(~isInner), 'ascend');
    gapOuter = diff(thvOuter);
    [maxGapOuter, mgoIdx] = max(gapOuter);
    zGapOuter = thvOuter(1) + 2*pi - thvOuter(end);
    if zGapOuter < maxGapOuter
        maxOuter1 = thvOuter(mgoIdx);
        isOuter1 = ~isInner & thVals <= maxOuter1;
        minOuter2 = thvOuter(mgoIdx+1);
        isOuter2 = ~isInner & thVals >= minOuter2;
        
        imgInner = false(size(img)); imgInner(imgIdxs(isInner)) = true;
        innerDists = bwdist(imgInner);

        if min(innerDists(imgIdxs(isOuter1))) > min(innerDists(imgIdxs(isOuter2)))
            thAdj(isOuter1) = thAdj(isOuter1) + 2*pi;
        else
            thAdj(isOuter2) = thAdj(isOuter2) - 2*pi;
        end
        adjustedOuter = true;
    end

    [minTh, minThIdx] = min(mod(thAdj, 2*pi));
    [maxTh, maxThIdx] = max(mod(thAdj, 2*pi));
    minThMult = floor(minTh / (2*pi));
    maxThMult = floor(maxTh / (2*pi));
    
    if minThMult ~= maxThMult
        warning('theta-discontinuity through polar axis');
        assert(~adjustedInner & ~adjustedOuter);
        if isInner(minThIdx)
            assert(~isInner(maxThIdx));
            thAdj(isInner) = mod(thAdj(isInner), 2*pi) + (2*pi)*(maxThMult+1);
        else
            assert(isInner(maxThIdx));
            thAdj(~isInner) = mod(thAdj(~IsInner), 2*pi) + (2*pi)*(maxThMult+1);
        end
    end
end

end