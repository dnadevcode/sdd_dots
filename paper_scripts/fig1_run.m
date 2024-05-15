hFig = sdd_gui

print('Fig1B.eps','-depsc','-r300');
print('Fig1B.png','-dpng','-r300');

% ax = gca;
exportgraphics(hFig,'Fig1B.pdf','Resolution',300)

print('Fig1B.jpg','-r300');


%%

% test SDD_GUI without any GUI.
sets = Core.Default.read_default_sets('sdd_fig3.txt',0);

sets.ratlim = 0.3;
sets.elim = 0.8;
sets.extractionMethod = 2;
% sets.folder = '/export/scratch/albertas/data_temp/DOTS/031523 h202 data/testFig3/image for slide 7.czi';
% 

    % create tabbed figure
    hFig = figure('Name', ['SDD-dots GUI v'], ...
        'Units', 'normalized', ...
        'OuterPosition', [0 0 0.3 0.3], ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'figure' ...
    );

    hPanel = uipanel('Parent', hFig);
    h = uitabgroup('Parent',hPanel);
    t1 = uitab(h, 'title', 'SDD');
    tsHCC = uitabgroup('Parent',t1);
%     hPanelImport = uitab(tsHCC, 'title', 'Dot import tab');

[output,hPanelResult,images,movies,barcodes] = sdd_process_folder(sets.folder , sets,tsHCC);

hPanelResult{1}.Children.SelectedTab  = hPanelResult{1}.Children.Children(2);

% hFig.Position = [100 100 540 400];
% grid on
% axis on
ax = gca;
ax.XLim = [450 660];
ax.YLim = [400 470];
% delete(nexttile(2))
% I2 = imcrop(gcf,[1 100 1 100]);

% gcf(hPanelResult{1}.Children.SelectedTab)

% J = imcrop(hFig,[60 40 100 90]);
set(gcf, 'Color', 'w')

A = gcf;
A.XDisplay;

hold on
nPixels = 1e4/sets.pxnm;
x = [ax.XLim(2)-nPixels-10 ax.XLim(2)+nPixels-nPixels-10];
y = [ax.YLim(2)-5 ,ax.YLim(2)-5 ];
plot(x,y,'Linewidth',2,'Color','white')
% text(0,0.05,'10 microns','Fontsize',10,'Color','white','Units','normalized')
set(gcf, 'Color', 'w')

%% Select 14

% ft = 'Times';
% fsz = 10;        
% %%%%%%%%%%%%%%%
% % Your Figure
% %%%%%%%%%%%%%%%
% set(findall(gcf,'type','text'), 'FontSize', fsz, 'Color', 'k','FontName', ft)
% set(gca,'FontSize', fsz, 'FontName', ft)



print(A,'Fig1C.png','-dpng','-r300');

%% 14:
sets.pixelSize = sets.pxnm;
Core.AnalysisPlot.detailed_analysis_plot(movies,barcodes,sets,14)
% ax = gca;
% ax.XLim = [450 660];
% ax.YLim = [400 470];

    print('Fig1D.png','-dpng','-r300');
