%%
% FilopodiaSegmentation.
% Copyright (C) 2018 B. Mattes, Y. Dang, S. Scholpp, R. Mikut, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and
% the following publication:
%
% Mattes, B., Dang, Y., Greicius, G., Kaufmann, L. T., Prunsche, B., 
% Rosenbauer, J., Stegmaier, J., Mikut, R., Özbek, S., Nienhaus, G. U., 
% Schug, A., Virshup D. M., Scholpp, S., "Wnt/PCP controls spreading of 
% Wnt/β-catenin signals by cytonemes in vertebrates". Elife, 7, e36953, 2018.
%
%%

%% get global variables
global settings;

figure(settings.mainFigure);
set(settings.mainFigure,'Visible','off');
if (settings.dirtyFlag == true)
    hold off;
end

set(settings.mainFigure, 'name',['Current Slice: ' num2str(settings.currentSlice) ' / ' num2str(size(settings.edgeImage,3))]);
%set(settings.mainAxes,'SortMethod','childorder');

%% plot the current slice
%axes(settings.mainAxes);
if (isempty(settings.filopodiaStart) || settings.useMaximumProjection == false || settings.dirtyFlag == true)
    if (~isfield(settings, 'rawImageHandle') || ~isvalid(settings.rawImageHandle) || settings.dirtyFlag == true)
        settings.rawImageHandle = imagesc( settings.rawImage(:,:,settings.currentSlice) ); colormap gray; hold on;
    else
        set(settings.rawImageHandle, 'CData', squeeze(settings.rawImage(:,:,settings.currentSlice)));
    end
else
    projectionRange = min(settings.currentSlice, settings.filopodiaStart(3)):max(settings.currentSlice, settings.filopodiaStart(3));
    imagesc( (max(squeeze(settings.rawImage(:,:,projectionRange)), [], 3)) ); hold on;
end

%% plot the filopodia that are located in the current slice
filopodiaLengths = [];
wntNegative = 0; wntPositive = 0;
for i=1:length(settings.segmentedFilopodia)
    lineColor = 'c';
    if (i==settings.selectedFilopodia)
        lineColor = 'm';
    end
    
    if (settings.currentSlice >= min(settings.segmentedFilopodia(i).positions(:,3)) && settings.currentSlice <= max(settings.segmentedFilopodia(i).positions(:,3)))
        currentPositions = settings.segmentedFilopodia(i).positions(:,3) == settings.currentSlice;
        
        if (~isfield(settings.segmentedFilopodia(i), 'filopodiaHandle') || isempty(settings.segmentedFilopodia(i).filopodiaHandle) || ~isvalid(settings.segmentedFilopodia(i).filopodiaHandle) || settings.dirtyFlag == true)
            settings.segmentedFilopodia(i).filopodiaHandle = plot(settings.segmentedFilopodia(i).positions(:,1), settings.segmentedFilopodia(i).positions(:,2), ['-' lineColor], 'LineWidth', 2);
            textPosition = mean(settings.segmentedFilopodia(i).positions);
            settings.segmentedFilopodia(i).filopodiaTextHandle = text('String', ['\bf ' num2str(i)], 'Position', [textPosition(1), textPosition(2)], 'FontSize', 20);
        
            if (settings.segmentedFilopodia(i).wntPositive == true)
                settings.segmentedFilopodia(i).filopodiaTipHandle = plot(settings.segmentedFilopodia(i).positions(end,1), settings.segmentedFilopodia(i).positions(end,2), 'og', 'MarkerFaceColor', 'g', 'MarkerSize', 9);
            else
                settings.segmentedFilopodia(i).filopodiaTipHandle = plot(settings.segmentedFilopodia(i).positions(end,1), settings.segmentedFilopodia(i).positions(end,2), 'or', 'MarkerFaceColor', 'r', 'MarkerSize', 9);
            end
        else
           set(settings.segmentedFilopodia(i).filopodiaHandle, 'Visible', 'on');
           set(settings.segmentedFilopodia(i).filopodiaTextHandle, 'Visible', 'on');
           set(settings.segmentedFilopodia(i).filopodiaTipHandle, 'Visible', 'on');           
        end
    else
        if (isfield(settings.segmentedFilopodia(i), 'filopodiaHandle') && ~isempty(settings.segmentedFilopodia(i).filopodiaHandle) && isvalid(settings.segmentedFilopodia(i).filopodiaHandle))
           set(settings.segmentedFilopodia(i).filopodiaHandle, 'Visible', 'off');
           set(settings.segmentedFilopodia(i).filopodiaTextHandle, 'Visible', 'off');
           set(settings.segmentedFilopodia(i).filopodiaTipHandle, 'Visible', 'off');
        end
    end
    
    filopodiaLengths = [filopodiaLengths; settings.segmentedFilopodia(i).length];
    
    if (settings.segmentedFilopodia(i).wntPositive == true)
        wntPositive = wntPositive+1;
    else
        wntNegative = wntNegative+1;
    end
end

%% plot the start of a new filipodia segmentation
if (~isempty(settings.filopodiaStart))
    plot(settings.filopodiaStart(1), settings.filopodiaStart(2), 'oy', 'MarkerSize', 9,'MarkerFaceColor', 'y');
end

%freezeColors;

if (settings.selectedFilopodia > 0 && settings.dirtyFlag == true)
    
    currentFilopodia = settings.segmentedFilopodia(settings.selectedFilopodia);
    
    rangeX = max(1,min(currentFilopodia.positions(:,1))):min(max(currentFilopodia.positions(:,1)), size(settings.rawImage, 1));
    rangeY = max(1,min(currentFilopodia.positions(:,2))):min(max(currentFilopodia.positions(:,2)), size(settings.rawImage, 2));
    rangeZ = max(1,min(currentFilopodia.positions(:,3))):min(max(currentFilopodia.positions(:,3)), size(settings.rawImage, 3));
    
    %% CLOSEUP XY Axes
    axes(settings.closeupXYAxes);
    xyImage = (max(squeeze(settings.rawImage(:,:,rangeZ)), [], 3));
    imagesc(xyImage); hold on;
    currentPositions = currentFilopodia.positions(:,3) == settings.currentSlice;
    plot(currentFilopodia.positions(:,1), currentFilopodia.positions(:,2), '-m', 'LineWidth', 2);
    plot(currentFilopodia.positions(currentPositions,1), currentFilopodia.positions(currentPositions,2), 'om', 'MarkerFaceColor','m', 'MarkerSize', 6);
    if (currentFilopodia.wntPositive)
        plot(currentFilopodia.positions(end,1), currentFilopodia.positions(end,2), 'og', 'MarkerFaceColor', 'g', 'MarkerSize', 9);
    else
        plot(currentFilopodia.positions(end,1), currentFilopodia.positions(end,2), 'or', 'MarkerSize', 9,'MarkerFaceColor', 'r');
    end
    hold off;
    axis([rangeX(1) rangeX(end) rangeY(1) rangeY(end)] + [-settings.previewPadding settings.previewPadding -settings.previewPadding settings.previewPadding]);
    xlabel('x');
    ylabel('y');
    
    %% CLOSEUP Z Axes
    axes(settings.closeupZAxes);
    xzImage = zeros(length(currentFilopodia.positions), size(settings.edgeImage, 3));
    for i=1:length(currentFilopodia.positions)
        xzImage(i,:) = squeeze(settings.rawImage(currentFilopodia.positions(i,2),currentFilopodia.positions(i,1),:));
    end
    
    imagesc((xzImage)'); hold on;
    currentPositions = currentFilopodia.positions(:,3) == settings.currentSlice;
    plot(1:length(currentFilopodia.positions(:,1)), currentFilopodia.positions(:,3), '-m', 'LineWidth', 2);
    plot(find(currentPositions > 0), currentFilopodia.positions(currentPositions,3), 'om', 'MarkerFaceColor','m', 'MarkerSize', 6);
    if (currentFilopodia.wntPositive)
        plot(length(currentPositions(:,1)), currentFilopodia.positions(end,3), 'og', 'MarkerFaceColor', 'g', 'MarkerSize', 9);
    else
        plot(length(currentPositions(:,1)), currentFilopodia.positions(end,3), 'or', 'MarkerSize', 9,'MarkerFaceColor', 'r');
    end
    hold off;
    
    %% CLOSEUP WNT XY Axes
    axes(settings.closeupXYWntAxes);
    xyWntImage = (max(squeeze(settings.wntImage(:,:,rangeZ)), [], 3));
    imagesc(xyWntImage); hold on;
    currentPositions = currentFilopodia.positions(:,3) == settings.currentSlice;
    plot(currentFilopodia.positions(:,1), currentFilopodia.positions(:,2), '-m', 'LineWidth', 2);
    plot(currentFilopodia.positions(currentPositions,1), currentFilopodia.positions(currentPositions,2), 'om', 'MarkerFaceColor','m', 'MarkerSize', 6);
    if (currentFilopodia.wntPositive)
        plot(currentFilopodia.positions(end,1), currentFilopodia.positions(end,2), 'og', 'MarkerFaceColor', 'g', 'MarkerSize', 9);
    else
        plot(currentFilopodia.positions(end,1), currentFilopodia.positions(end,2), 'or', 'MarkerSize', 9,'MarkerFaceColor', 'r');
    end
    hold off;
    axis([rangeX(1) rangeX(end) rangeY(1) rangeY(end)] + [-settings.previewPadding settings.previewPadding -settings.previewPadding settings.previewPadding]);
    xlabel('x');
    ylabel('y');
    
    settings.prevSelectedFilopodia = settings.selectedFilopodia;
    
    axes(settings.statsAxes);
    imshow(cat(3, imadjust(xyImage), imadjust(xyWntImage), zeros(size(xyWntImage))));
    %axis([100, 800, 100, 800]);
    axis([rangeX(1) rangeX(end) rangeY(1) rangeY(end)] + [-settings.previewPadding settings.previewPadding -settings.previewPadding settings.previewPadding]);
end

axes(settings.mainAxes);
if (~isempty(settings.xLim) && ~isempty(settings.yLim))
    set(settings.mainAxes, 'XLim', settings.xLim);
    set(settings.mainAxes, 'YLim', settings.yLim);
end

%% plot some stats
if (~isfield(settings, 'currentSliceTextHandle') || ~isvalid(settings.currentSliceTextHandle) || settings.dirtyFlag == true)
    settings.currentSliceTextHandle = text('String', ['\bf Current Slice: ' num2str(settings.currentSlice) ' / ' num2str(size(settings.edgeImage,3))], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.98]);
else
    set(settings.currentSliceTextHandle, 'String', ['\bf Current Slice: ' num2str(settings.currentSlice) ' / ' num2str(size(settings.edgeImage,3))]);
end
if (~isfield(settings, 'currentCellTextHandle') || ~isvalid(settings.currentCellTextHandle) || settings.dirtyFlag == true)
    settings.currentCellTextHandle = text('String', ['\bf Current Cell: ' num2str(settings.currentCell)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.96]);
else
    set(settings.currentCellTextHandle, 'String', ['\bf Current Cell: ' num2str(settings.currentCell)]);
end
if (~isfield(settings, 'numFilopodiaTextHandle') || ~isvalid(settings.numFilopodiaTextHandle) || settings.dirtyFlag == true)
    settings.numFilopodiaTextHandle = text('String', ['\bf Number of Filopodia: ' num2str(length(settings.segmentedFilopodia))], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.94]);
else
    set(settings.numFilopodiaTextHandle, 'String', ['\bf Number of Filopodia: ' num2str(length(settings.segmentedFilopodia))]);
end
if (~isfield(settings, 'averageLengthTextHandle') || ~isvalid(settings.averageLengthTextHandle) || settings.dirtyFlag == true)
    settings.averageLengthTextHandle = text('String', ['\bf Average Length (\mum): ' num2str(mean(filopodiaLengths), 4) ' \pm ' num2str(std(filopodiaLengths), 4)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.92]);
else
    set(settings.averageLengthTextHandle, 'String', ['\bf Average Length (\mum): ' num2str(mean(filopodiaLengths), 4) ' \pm ' num2str(std(filopodiaLengths), 4)]);
end
if (~isfield(settings, 'wntNegativeTextHandle') || ~isvalid(settings.wntNegativeTextHandle) || settings.dirtyFlag == true)
    settings.wntNegativeTextHandle = text('String', ['\bf Wnt Negative Filopodia: ' num2str(wntNegative/length(settings.segmentedFilopodia)*100, 4) ' %'], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.90]);
else
    set(settings.wntNegativeTextHandle, 'String', ['\bf Wnt Negative Filopodia: ' num2str(wntNegative/length(settings.segmentedFilopodia)*100, 4) ' %']);
end
if (~isfield(settings, 'wntPositiveTextHandle') || ~isvalid(settings.wntPositiveTextHandle) || settings.dirtyFlag == true)
    settings.wntPositiveTextHandle = text('String', ['\bf Wnt Positive Filopodia: ' num2str(wntPositive/length(settings.segmentedFilopodia)*100, 4) ' %'], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.88]);
else
    set(settings.wntPositiveTextHandle, 'String',  ['\bf Wnt Positive Filopodia: ' num2str(wntPositive/length(settings.segmentedFilopodia)*100, 4) ' %']);
end

if (settings.dirtyFlag == true)
    text('String', '\bf XY-Slice (memCherry)', 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.0 0.01], 'BackgroundColor', [0.0, 0.0, 0.0, 0.5]);
    text('String', '\bf XY-Projection (memCherry)', 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.0 0.51], 'BackgroundColor', [0.0, 0.0, 0.0, 0.5]);
    text('String', '\bf XY-Projection (Wnt8-GFP)', 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.0 0.01], 'BackgroundColor', [0.0, 0.0, 0.0, 0.5]);
    text('String', '\bf XY-Trace vs. Z-Projection (memCherry)', 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.5 0.51], 'BackgroundColor', [0.0, 0.0, 0.0, 0.5]);
    text('String', '\bf Composite (red: memCherry, green: Wnt8-GFP)', 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.5 0.01], 'BackgroundColor', [0.0, 0.0, 0.0, 0.5]);
end

    %%%%%%% Selection information
if (settings.selectedFilopodia > 0 && settings.dirtyFlag == true)
    text('String', ['\bf Selected Filopodium: ' num2str(settings.selectedFilopodia)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.0 0.98]);
    text('String', ['\bf Length (\mum): ' num2str(settings.segmentedFilopodia(settings.selectedFilopodia).length)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.0 0.96]);
	text('String', ['\bf Attached to Cell: ' num2str(settings.segmentedFilopodia(settings.selectedFilopodia).cellId)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.0 0.94]);
    if (settings.segmentedFilopodia(settings.selectedFilopodia).wntPositive == true)
        text('String', '\bf Wnt Positive', 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.0 0.92]);
    else
        text('String', '\bf Wnt Negative', 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [1.0 0.92]);
    end
end

%% correct the axes settings
set(settings.mainAxes,'XTick',[]);
set(settings.mainAxes,'YTick',[]);
set(settings.mainAxes,'TickDir','out');
set(settings.closeupXYAxes,'XTick',[]);
set(settings.closeupXYAxes,'YTick',[]);
set(settings.closeupXYAxes,'TickDir','out');
set(settings.closeupZAxes,'XTick',[]);
set(settings.closeupZAxes,'YTick',[]);
set(settings.closeupZAxes,'TickDir','out');
set(settings.closeupXYWntAxes,'XTick',[]);
set(settings.closeupXYWntAxes,'YTick',[]);
set(settings.closeupXYWntAxes,'TickDir','out');
set(settings.statsAxes,'XTick',[]);
set(settings.statsAxes,'YTick',[]);
set(settings.statsAxes,'TickDir','out');
% 
% set(settings.mainAxes, 'unit', 'normalized', 'position', [0,0,0.5,1.0]);
% set(settings.closeupXYAxes, 'unit', 'normalized', 'position', [0.5,0.5,0.25,0.5]);
% set(settings.closeupZAxes, 'unit', 'normalized', 'position', [0.75,0.5,0.25,0.5]);
% set(settings.closeupXYWntAxes, 'unit', 'normalized', 'position', [0.5,0.0,0.25,0.5]);
% set(settings.statsAxes, 'unit', 'normalized', 'position', [0.75,0.0,0.25,0.5]);

%% set the dirty flag to false
settings.dirtyFlag = false;
set(settings.mainFigure,'Visible','on');