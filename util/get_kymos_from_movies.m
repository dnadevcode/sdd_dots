function [kymos, lineParams, xyPars,distance] = get_kymos_from_movies( molM, bwM, sPer, method)
    % get_kymos_from_movies this function gets kymos from movies
    
    %   Args:
    %       molM - molecule movie
    %       bwM - molecule bitmask
    %       sPer - how many pixels to take perpendicularly
    %       method - extraction method
    %
    %   Returns:
    %       kymos - extracted kymograph
    %       lineParams - line parameters for extracted kymograph
    %       xyPars - xy parameters for extracted kymo
    
    if nargin < 4
        method = 1;
    end

    % These will be returned as output
    kymos = cell(1, length(molM));
    lineParams = cell(1, length(molM));
    xyPars = cell(1, length(molM));
    distance =  cell(1, length(molM));

    import Core.LineExtraction.fit_line_method;
    import Core.LineExtraction.fit_spline_method;

    %%
    switch method
        case 1 %"linear"
            [kymos,lineParams] = fit_line_method(molM,bwM,sPer);
        case 2 % spline
             [kymos,lineParams,xyPars,distance] = fit_spline_method(molM,bwM,sPer);
%         case 2 % match-pairs
        otherwise
            error('No valid alignment method selected');
    end
    
%%
    %   % plot
    plotExample = 0;
    if plotExample ==1
        %%
%         i=21
%         out = bwskel(bwM{i}==1,'MinBranchLength',20);
    
%         nonnans = find(out==1);
%         [row, col] = ind2sub(size(out), nonnans);
%         mat = molM{i}(:,:,1);
%         weight = mat(nonnans);
%         f=fit(row,col,'smoothingspline','Weights',weight);% make sure that the line is calculated in y direction (possible issue otherwise, need some tests..)
%         figure,plot(1:size(molM{idx},2),f(1:size(molM{idx},2)))
%     figure,imagesc(out)
%         [coor1 coor2]=find(out==1); % Finding all the co-ordinates for the corresponding component
%         yy1 = smooth(coor2,coor1,0.5,'loess');
% %         yqs = spline(coor2,coor1,1:1:length(coor1));
% %         figure,plot(coor2,yy1)
% %         figure,imagesc(molM{i})
% % %         figure,imagesc(bwM{i})
% %         hold on
% %         plot(coor2,yy1,'red')
% % %         
%         [curve, goodness, output] = fit(coor2,yy1,'smoothingspline');% ,'SmoothingParam',0.5
% %         figure,plot(curve,coor2,coor1)
%         
%         figure,imagesc(molM{i})
%         hold on
%         plot(curve)
        % now sample every px
        %%
%         BW = poly2mask(coor1,coor2,120,120);
        
          distance = zeros(1,length(yy1)-1);
        for i=1:length(yy1)-1
           distance(i) = sqrt((yy1(i+1)-yy1(i))^2+(coor2(i+1)-coor2(i))^2); % straight line distance
        end

%         plot(f(1:size(molM{idx},2)),1:size(molM{idx},2),'red')
        idx=1
%            [k,b] = get_line_parameters(bwM{i});
%       kymos{i} = get_kymo(molM{i}, k , b, sPer);
        figure,
        tiledlayout(1,3);nexttile
        imagesc(molM{idx})
        nexttile
%         imagesc(dotM{idx})
        imagesc(molM{idx})

        hold on
        plot(-lineParams{idx}(1)*(1:size(molM{idx},2))+lineParams{idx}(2),'redx')
          nexttile
%         imagesc(dotM{idx})
        imagesc(molM{idx}')
            hold on
            
            plot(xF,yF,'redx')
%             
        colormap(gray)
        %%
%         xd = 0.1;
%         xvals = 1:xd:size(molM{idx},1);
%         yvals = f(1:xd:size(molM{idx},1));
%         allD = zeros(1,length(xvals)-1);
%         for i=1:length(xvals)-1
%            allD(i) = sqrt((xvals(i+1)-xvals(i))^2+(yvals(i+1)-yvals(i))^2); % straight line distance
%         end
%         distAlong = cumsum(allD);
%         % 
%         pxPos = 0:round(sum(allD));
%         idxPx = zeros(1,length(pxPos));
%         idxPx(1)=1;
%         for idpxPos = 1:pxPos(end)
%             idxPx(idpxPos+1) = find(distAlong >= idpxPos ,1,'first');
%         end
% %         find
% 
%         xF = xvals(idxPx);
%         yF = yvals(idxPx);
%         figure,plot(xF,yF)
        
        % then at each point, we can draw a diagonal (line) between two
        % points, and perpendicular to that will give us the perpendicular
        % points for the kymo
    end
end

