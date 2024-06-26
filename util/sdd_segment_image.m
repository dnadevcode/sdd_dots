function [movies, scores, sets, lengthLims, lowLim, widthLims, bgCutOut, bgCutOut2,bgCutOut22,meh] = sdd_segment_image(images, imageName, imageNumber, runNo, sets, tiles)
    % sdd_segment_image - segments image
    %
    %
    %   Args:
    %       images, imageName, imageNumber, runNo, sets, tiles
    %
    %   Returns:
    %       movies, scores, optics, lengthLims, lowLim, widthLims,
    %       bgCutOut, bgCutOut2

  registeredIm = images.registeredIm;
  imAverage = images.imAverage;
  centers = images.centers;
  hasDots = isfield(images, 'dotIm');
  hasDots2 = isfield(images, 'dotIm2'); % coud make into a loop for many

  if hasDots
    dotIm = images.dotIm;
  else
      bgCutOut2 = [];
  end

  if hasDots2
      dotIm2 = images.dotIm2;
  else
      bgCutOut22 = [];
  end

  %% get params, can possibly be skipped
  foundOptics = 0;


  if isfield(sets, 'opticsFile') && (isfile(sets.opticsFile) || isfile(fullfile(sets.targetFolder, sets.opticsFile)))

    try
      [sets.NA, sets.pixelSize, sets.waveLength] = get_optic_params(fullfile(sets.targetFolder, sets.opticsFile));
    catch
      [sets.NA, sets.pixelSize, sets.waveLength] = get_optic_params(sets.opticsFile);
    end

    sets.sigma = 1.22 * sets.waveLength / (2 * sets.NA) / sets.pixelSize; % Calculate width of PSF
    sets.logSigma = sets.sigma;
    foundOptics = 1;
  else
    sets.NA = nan;
    sets.waveLength = nan;
  end

  if isfield(sets, 'logSigmaNm') && isfield(sets, 'pxnm')

    if not(foundOptics)
      sets.sigma = sets.logSigmaNm / sets.pxnm;
    end

    sets.logSigma = sets.logSigmaNm / sets.pxnm;
    sets.pixelSize = sets.pxnm;
    foundOptics = 1;
  end

  if not(foundOptics)
    throw(MException('segment:optics', 'No optics file or optics settings found'))
  end
  
 % Filter image with LoG filter 
[filt, dist] = wd_calc(sets.sigma); 
%%
  tic;
  if ~isa(imAverage, 'double')
    imAverage = double(imAverage);
    fprintf('Averaged image has been converted to type "double"\n');
  end

  % log filter
  logim = imfilter(imAverage, filt,'replicate');


  % Find zero crossing contours
  if sets.showMolecules
%     figure(1 + (imageNumber - 1) * 5)
%     t = tiledlayout(hPanelResult,4,2,'TileSpacing','tight','Padding','tight');
    axes(tiles.logFilt);
    imshow(logim, 'InitialMagnification', 'fit')
 
%     ax1 = uiaxes(hPanelResult);
%     imshow(logim, 'InitialMagnification', 'fit','Parent',ax1)
    title([imageName, ' LoG filtered'])
  end
  
    % Calculate edge score around all edges
    [~, Gdir] = imgradient(logim);

    thedges = imbinarize(logim, 0);
%     thedges = imclose(thedges, true(ceil( optics.logSigma))); % made this dependent on logSigma

    thedges(1:end,[ 1 end]) = 1; % things around the boundary should also be considered
    thedges([ 1 end],1:end) = 1;

    % boundaries
    [B, L] = bwboundaries(1-thedges, 'noholes'); % holes in thedges is noholes in 1-thedges





%     tic % all lengths min
    allFeatLengths =  cellfun(@(x) max(max(x)-min(x)),B); % bar length at least this times sqrt(2)





    allPxNum = cellfun(@(x) size(x,1),B);
%     toc
    % lengths and repetitions
%     allFeatLengths =  cellfun(@(x) sqrt(sum((max(x)-min(x)).^2)),B);
%     numRepetitionsX  = cellfun(@(x) size(x,1)./length(unique(x(:,1))),B); % something quicker than unique?

%     numRepetitionsX  = cellfun(@(x) size(x,1)./length(unique(x(:,1))),B); % something quicker than unique?
%     numRepetitionsY  = cellfun(@(x) size(x,1)./length(unique(x(:,2))),B);
%     toc
%     numAllowedCrossings = 6; % number of allowed crossings, i.e. how wiggly we allow molecule to be
    % remove regions which do not satisfy initial length constrains
    acceptedMols = logical((allFeatLengths>=sets.lengthLims(1)).*(allFeatLengths<=sets.lengthLims(2)).*(allPxNum<=min(max(size(logim)),2000)));

   if sets.removeCloseMolecules % remove molecules close to the edge
        edgeVals = [unique(L([1:sets.pixelsCloseMolecules end-sets.pixelsCloseMolecules+1:end],:)); unique(L(sets.pixelsCloseMolecules+1:end-sets.pixelsCloseMolecules,[1:sets.pixelsCloseMolecules end-sets.pixelsCloseMolecules+1:end]))];
        edgeVals = edgeVals(edgeVals~=0);
        %         acceptedMols(edgeVals(edgeVals~=0)) = 0;


        curAccepted = find(acceptedMols);
        import Core.Distance.pairwise_distances_molecule;
        goodMols = pairwise_distances_molecule(B(curAccepted),sets.pixelsCloseMolecules);
        acceptedMols(curAccepted(~goodMols)) = 0;
        acceptedMols(edgeVals) = 0;

    end
    B = B(acceptedMols);
    
    molPos = find(acceptedMols);
%     
%     figure
%     hold on
%     for i =1:length(B)
%         plot(B{i}(:,2),B{i}(:,1))
% %         text(B{i}(1,1),B{i}(1,2),num2str(i))
%     end
%     set( gca, 'ydir', 'reverse' )
%     toc
    % L needs to be relabeled.
  
  
    % now remove some of the features before calculating scores. Also size
    % of num  points can't be 2x


%     shortFeats = cellfun(@(x) length(unique(x(:,1))) <= sets.MaxNumPts,B);
%     B = B(shortFeats);

        
        
  fprintf('Total number of regions: %i regions found in %.1f sec.\n', length(B),toc);
 
    meh = zeros(1, length(B));
    stat = @(h) mean(h); % This should perhaps be given from the outside

    tic
  for k = 1:length(B)% Filter out any regions with artifacts in them
%     k / only if some centers to remove // % check this later to save time
%     if not(isempty(centers))
%       in = inpolygon(centers(:, 1), centers(:, 2), B{k}(:, 2), B{k}(:, 1));
%     else
%       in = 0;
%     end

%     if ~in
      meh(k) = edge_score(B{k}, logim, Gdir, floor(dist/2), stat); %/optics.sigma^3;% What is the point of this division? //Erik
%     else
%       meh(k) = -Inf;
%     end
  end
  fprintf('Edge scores calculated in %.1f sec.\n',toc);

  % If showScores, show histogram of log of region scores
  if sets.showScores
%     figure(2 + (imageNumber - 1) * 5)
    axes(tiles.molScores);
    h1 = histogram(log(meh(meh > 1)));
    title([imageName, ' edge scores'])
  end

  % If showMolecules, show image to outline molecules
  if sets.showMolecules
    molFigNum = 3 + (imageNumber - 1) * 5;
%     figure(molFigNum)
%     movies.c = nexttile(t);
    axes(tiles.molDet);
    imshow(mat2gray(imAverage), 'InitialMagnification', 'fit');
    title([imageName, ' detected molecules'])

    if hasDots
      dotFigNum = 4 + (imageNumber - 1) * 5;
%       figure(dotFigNum)
      axes(tiles.dotDet);
      imshow(mat2gray(dotIm), 'InitialMagnification', 'fit');
      title([imageName, ' dot image']);
    else
        dotFigNum = [];
    end
    if hasDots2
        dotFigNum2 = 5 + (imageNumber - 1) * 5;
        %       figure(dotFigNum)
        axes(tiles.dotDet2);
        imshow(mat2gray(dotIm2), 'InitialMagnification', 'fit');
        title([imageName, ' dot image']);
    else
        dotFigNum2 = [];
    end

  else
      dotFigNum = [];
      dotFigNum2 = [];
  end

  %%%%%%%%%%%%%%% TWEAK PARAMETERS %%%%%%%%%%%%%%%
  % lowLim = exp(-4.5);     % Set the low score threshold to consider a region "signal" (very important)
  % highLim = exp(24);   % Arbitrary higher bound not utilized at this point. (ignore this for now)
  % elim = .8;			 % Set lower limit for eccentricity of region (removes dots and circles and keeps long shapes)
  % ratlim = .5;		 % Set lower limit for ratio of area of region to the convex region formed around (removes "wiggly" regions)
  % lengthLims = [50 1000]; % Set lower and upper limit for the length of the molecule (pixels)
  % widthLims = [0 50]; 		% Set lower and upper limit for the width of the molecule (pixels)
  %%%%%%%%%%%%%%% TWEAK PARAMETERS %%%%%%%%%%%%%%%

  lowLim = sets.lowLim;
  highLim = sets.highLim;
  elim = sets.elim;
  ratlim = sets.ratlim;
  lengthLims = sets.lengthLims;
  widthLims = sets.widthLims;
  sigmaBgLim = sets.sigmaBgLim;
  
  bg = L == 0;
  % Filter molecules via the tweak parameters above
  accepted = 0;
  D = B;
  newL = zeros(size(L));
  trueedge = cell(1, length(B));
  scores = nan(1, length(B));

  % Background stuff
  bgPixels = imAverage(bg);    
  bgMean = trimmean(bgPixels(:), 10);
  
    if length(bgPixels) > 10000
        bgPixels(bgPixels>bgMean+2*std(bgPixels)) = [];
    end

  bgCutOut = nan(size(imAverage));
  bgCutOut(bg) = imAverage(bg);
  
  if sigmaBgLim > 0
    bgStd = sqrt(trimmean(bgPixels(:).^2, 10) - bgMean.^2);
  end

  bgSubtractedIm = cellfun(@(x) x- bgMean,registeredIm,'un',false);
  for ix=1:length(bgSubtractedIm)
      bgSubtractedIm{ix}(bgSubtractedIm{ix} <= 0) = nan;
  end

  if sets.autoThreshBars
     sets.autoThreshBarsold = 0;
     if sets.autoThreshBarsold
        logEdgeScores = log(meh(meh > 1));
        lowestScore = min(logEdgeScores);
        [autoThreshRel, em] = graythresh(logEdgeScores(:) - lowestScore);
        autoThresh = exp(autoThreshRel * (max(logEdgeScores) - lowestScore) + lowestScore);
        lowLim = autoThresh;
     else
           % calculate some edge scores for random locations
        nmrand = 1000;
        allScores = zeros(1, nmrand);
        dim = size(logim,[1 2]);
        nPt = sets.lenRandBar;%sets.lengthLims(1);
        bg([1: floor(dist/2) end- floor(dist/2)+1:end],:) = 0;
        bg(:,[1: floor(dist/2) end- floor(dist/2)+1:end]) = 0;
%         erodedbg = imerode(bg,ones(5,5));
        bgIndices = find(bg);
        rng("default"); % keep same indexes (for reproducibility)

        % For future: could calculate 
%         randbgind = randsample(bgIndices,nmrand);
%         [bgIx bgIy] = ind2sub(dim,randbgind);
%         randMeh

%         [bgIx bgIy] = ind2sub(dim,find(ones(size(bg)))); %all

%         [bgIx bgIy] = ind2sub(dim,find(erodedbg));
%         tic % edge scores for absolutely all pixels
%         allScores = arrayfun(@(x,y) edge_score([x y], logim, Gdir, floor(dist/2), stat),bgIx,bgIy );
%         toc
%         for jj=1:length(bgIndices)
%             allScores(jj) = edge_score([ind2sub(dim,bgIndices(jj))], logim, Gdir, dist, stat);
%         end

        for k = 1:nmrand% Filter out any regions with artifacts in them
            indices = randsample(bgIndices,nPt);
            [I J] = ind2sub(dim,indices); %(nPt*(k-1)+1:nPt*k)
            allScores(k) = edge_score([I J], logim, Gdir, floor(dist/2), stat); %how many points along the gradient to take?
        end
       lowLim = mean(allScores)+sets.numthreshautoEdgeScore*std(allScores); % might be some variation

     end
  end

  if sets.showScores
%     figure(2 + (imageNumber - 1) * 5)
    axes(tiles.molScores)
    hold on
    %    line([log(autoThresh) log(autoThresh)],[0 max(h1.Values)],'LineStyle','--','Color','red','LineWidth',2)
    if sets.autoThreshBars
      mess = 'Automated threshold';
      line([log(lowLim) log(lowLim)], [0 max(h1.Values)], 'LineStyle', '--', 'Color', 'red', 'LineWidth', 2)
    else
      line([log(lowLim) log(lowLim)], [0 max(h1.Values)], 'LineStyle', '--', 'Color', 'black', 'LineWidth', 2)
      mess = 'User set threshold';
    end

    text(1.1 * log(lowLim), 2/3 * max(h1.Values), mess, 'FontSize', 14)
    hold off
    if sets.autoThreshBarsold==0&&sets.autoThreshBars
        axes(tiles.bgScores);
        histogram(allScores)
        title([imageName, ' edge score background histogram'])
    end

  end


  
if sets.showMolecules
    axes(tiles.molDet);
    hold on
end

stats = cell(1,length(B));
currentAccepted = zeros(1,length(B));

for k = 1:length(B)% Filter any edges with lower scores than lim
    [acc, stats{k}, img]  = mol_filt(B{k}, meh(k), lowLim, highLim, elim, ratlim, lengthLims, widthLims);

    if sigmaBgLim > 0 % is this correct if B has some elements removed
        numPixelsInMol = sum(L == molPos(k), 'all');
        intensAcc = sum(imAverage(L == molPos(k))) >= numPixelsInMol * bgMean + sqrt(numPixelsInMol) * sigmaBgLim * bgStd;
    else
        intensAcc = 1;
    end

    if acc && intensAcc
        currentAccepted(k) = 1;
        accepted = accepted + 1;
        trueedge{accepted} = D{k};
        scores(k) = meh(k);
        newL(L == molPos(k)) = accepted; % is this used somewhere

%         if sets.showMolecules
%             %         figure(molFigNum)
%             plot(trueedge{accepted}(:, 2), trueedge{accepted}(:, 1));
%         end

    else
        D{k} = [];
    end

end
  
% if sets.removeCloseMolecules % final check: is one of the pixels close to any of previous found pixels
%     acceptedMols = find(currentAccepted);
%     import Core.Distance.pairwise_distances_molecule;
%     goodMols = pairwise_distances_molecule(D(acceptedMols),sets.pixelsCloseMolecules);
%     trueedge = D(acceptedMols(goodMols));
%     accepted = length(trueedge);
%     D = D(acceptedMols(goodMols));
% end
% 

if sets.showMolecules
    for k = 1:accepted % Filter any edges with lower scores than lim
        plot(trueedge{k}(:, 2), trueedge{k}(:, 1));
    end
    hold off
end


trueedge(accepted + 1:end) = [];
stats = stats(~cellfun('isempty', D));
D = D(~cellfun('isempty', D)); % Remove empty entries (where molecules have been filtered)
scores = scores(~isnan(scores));

if hasDots && sets.showMolecules
    axes(tiles.dotDet);
    hold on

    for k = 1:length(trueedge)
        %       figure(dotFigNum)
        plot(trueedge{k}(:, 2), trueedge{k}(:, 1));
    end

    hold off

end

  fprintf('Found %i molecules with log edge score >%.2f, eccentricity >%.2f, aRat >%.2f, %i< length <%i, and %i< width <%i.\n', accepted, log(lowLim), elim, ratlim, lengthLims(1), lengthLims(2), widthLims(1), widthLims(2));
  t = toc;
  fprintf('Segmentation completed in %.1f seconds.\n', t);

  % Store each molecules in its own image (this might be very slow)
  folderName = subsref(dir(sets.targetFolder), substruct('.', 'folder'));

  if hasDots
      if hasDots2
        [molM, bwM, dotM, dotM2,pos] = generate_molecule_images_fast(D, newL, bgSubtractedIm, dotIm, dotIm2, folderName, runNo, imageName, sets.edgeMargin, sets);
      else
        [molM, bwM, dotM, dotM2, pos] = generate_molecule_images_fast(D, newL, bgSubtractedIm, dotIm, [], folderName, runNo, imageName, sets.edgeMargin, sets);
      end
  else
    [molM, bwM, dotM, dotM2, pos] = generate_molecule_images_fast(D, newL, bgSubtractedIm, [],[], folderName, runNo, imageName, sets.edgeMargin, sets);
  end

  movies.imageName = imageName;
  movies.molM = molM;
  movies.bwM = bwM;
  movies.pos = pos;
  movies.trueedge = trueedge;
  movies.molRunName = fullfile(folderName, ['molecules_run',num2str(runNo)]);
  movies.runNo = runNo;
  movies.stats = stats;
  
  if sets.showMolecules
    movies.molFigNum = molFigNum;
  end

  if hasDots
    movies.dotFigNum = dotFigNum;
    movies.dotM = dotM;
    
    bgCutOut2 = nan(size(dotIm)); % background
    bgCutOut2(L ==0) = dotIm(L ==0);

    if sets.showMolecules
    %     figure(1 + (imageNumber - 1) * 5)
    %     t = tiledlayout(hPanelResult,4,2,'TileSpacing','tight','Padding','tight');
    axes(tiles.bg);
    imagesc(bgCutOut2);
    axis equal
    axis off
%     imshow(bgCutOut2, 'InitialMagnification', 'fit')

    colormap(gray);
    %     ax1 = uiaxes(hPanelResult);
    %     imshow(logim, 'InitialMagnification', 'fit','Parent',ax1)
    title([imageName, ' bg pixels'])
    end

    bgCutOut2 = bgCutOut2(~isnan(bgCutOut2));
    bgMean2 =  trimmean(bgCutOut2(:), 10);
    if length(bgCutOut2(:)) > 10000
        bgCutOut2 = bgCutOut2(bgCutOut2<bgMean2+2*nanstd(bgCutOut2(:)));
    end

  end

  if hasDots2

    movies.dotFigNum2 = dotFigNum2;
    movies.dotM2 = dotM2;
    
    bgCutOut22 = nan(size(dotIm2)); % background
    bgCutOut22(L ==0) = dotIm2(L ==0);

    if sets.showMolecules
    %     figure(1 + (imageNumber - 1) * 5)
    %     t = tiledlayout(hPanelResult,4,2,'TileSpacing','tight','Padding','tight');
    axes(tiles.bg2);
%     imshow(bgCutOut22, 'InitialMagnification', 'fit')

    imagesc(bgCutOut22);
    colormap(gray);
    axis equal
    axis off

    %     ax1 = uiaxes(hPanelResult);
    %     imshow(logim, 'InitialMagnification', 'fit','Parent',ax1)
    title([imageName, 'dot 2 bg pixels'])
    end

    bgCutOut22 = bgCutOut22(~isnan(bgCutOut22));
    bgMean22 =  trimmean(bgCutOut22(:), 10);
    if length(bgCutOut22(:)) > 10000
        bgCutOut22 = bgCutOut22(bgCutOut22<bgMean22+2*std(bgCutOut22(:),'omitnan'));
    end
  end
  
end
