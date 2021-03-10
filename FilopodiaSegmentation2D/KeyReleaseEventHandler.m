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

%% the key event handler
function KeyReleaseEventHandler(src,evt)
global settings;

%% get current modifier keys
modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
shiftPressed = ismember('shift',modifiers);
ctrlPressed = ismember('control',modifiers);
altPressed = ismember('alt',modifiers);

%% switch between the images of the loaded series
if (strcmp(evt.Key, 'rightarrow'))
    settings.currentImage = min(max(length(settings.gfpImage)),settings.currentImage+1);
    UpdateVisualization;
elseif (strcmp(evt.Key, 'leftarrow'))
    settings.currentImage = max(1,settings.currentImage-1);
    UpdateVisualization;
    
    %% not implemented yet, maybe use for contrast or scrolling
elseif (strcmp(evt.Key, 'uparrow'))
    settings.currentCell{settings.currentImage} = settings.currentCell{settings.currentImage} + 1;
    UpdateVisualization;
elseif (strcmp(evt.Key, 'downarrow'))
    settings.currentCell{settings.currentImage} = max(1,settings.currentCell{settings.currentImage} - 1);
    UpdateVisualization;
elseif (strcmp(evt.Character, '+'))
    settings.clusterRadius{settings.currentImage} = settings.clusterRadius{settings.currentImage} + 1;
    deletionIndices = [];
    for i=1:size(settings.selectedEndPoints{settings.currentImage},1)
        if (settings.selectedEndPoints{settings.currentImage}(i,settings.selectionIndex) == settings.currentCell{settings.currentImage})
            deletionIndices = [deletionIndices, i];
        end
    end
    settings.selectedEndPoints{settings.currentImage}(deletionIndices, :) = [];
    TraceFilopodia;
    
elseif (strcmp(evt.Character, '-'))
    settings.clusterRadius{settings.currentImage} = max(0, settings.clusterRadius{settings.currentImage} - 1);
    deletionIndices = [];
    for i=1:size(settings.selectedEndPoints{settings.currentImage},1)
        if (settings.selectedEndPoints{settings.currentImage}(i,settings.selectionIndex) == settings.currentCell{settings.currentImage})
            deletionIndices = [deletionIndices, i];
        end
    end
    settings.selectedEndPoints{settings.currentImage}(deletionIndices, :) = [];
    TraceFilopodia;
    
elseif (strcmp(evt.Character, '.'))
    settings.wntPositiveThreshold = min(settings.wntPositiveThreshold+settings.wntThresholdStep, 1);
    UpdateVisualization;
    
elseif (strcmp(evt.Character, ','))
    settings.wntPositiveThreshold = max(settings.wntPositiveThreshold-settings.wntThresholdStep, 0);
    UpdateVisualization;
    
    %% add a new filopodia tip at the cursor location
elseif (strcmp(evt.Character, 'a'))
    clickPosition = round(ginput(1));
    settings.endPoints{settings.currentImage} = [settings.endPoints{settings.currentImage}; size(settings.endPoints{settings.currentImage},1)+1, 0, clickPosition(1), clickPosition(2), 0, 0, 0, settings.currentCell{settings.currentImage};];
    settings.selectedEndPoints{settings.currentImage} = [settings.selectedEndPoints{settings.currentImage}; size(settings.endPoints{settings.currentImage},1), 0, clickPosition(1), clickPosition(2), 0, 0, 0, settings.currentCell{settings.currentImage};];
    
    if (settings.autoUpdate == true)
        TraceFilopodia;
    else
        UpdateVisualization;
    end
    
elseif (strcmp(evt.Character, 'd'))
    %% select the region of interest
    h = imfreehand;
    if (~isempty(h))
        maskImage = createMask(h, settings.imageHandle);
        
        if (sum(maskImage(:)) > 0)
            deletionIndices = [];
            for i=1:size(settings.selectedEndPoints{settings.currentImage},1)
                currentPosition = settings.selectedEndPoints{settings.currentImage}(i,settings.positionIndices);
                if (maskImage(currentPosition(2), currentPosition(1)) > 0)
                    deletionIndices = [deletionIndices, i];
                end
            end
            settings.selectedEndPoints{settings.currentImage}(deletionIndices,:) = [];
        else
            clickPosition = get(gca, 'currentpoint');
            clickPosition = round(clickPosition(1,1:2));
            minDist = inf;
            minIndex = 1;
            for i=1:size(settings.selectedEndPoints{settings.currentImage})
                distance = sqrt(sum((settings.selectedEndPoints{settings.currentImage}(i,3:4) - clickPosition).^2));
                
                if (distance < minDist)
                    minDist = distance;
                    minIndex = i;
                end
            end
            
            if (minDist < settings.meanIntensityWindowSize)
                settings.selectedEndPoints{settings.currentImage}(minIndex,:) = [];
            end
        end
        
        if (settings.autoUpdate == true)
            TraceFilopodia;
        else
            UpdateVisualization;
        end
    end
    
elseif (strcmp(evt.Character, 'g'))
    SaveProject;
    
elseif (strcmp(evt.Character, 'i'))
    clickPosition = round(ginput(1));
    minDist = inf;
    minIndex = 1;
    for i=1:length(settings.currentFilopodia{settings.currentImage})
        if (~isempty(settings.currentFilopodia{settings.currentImage}(i).positions))
            distance = sqrt(sum((double(settings.currentFilopodia{settings.currentImage}(i).positions(end,:)) - clickPosition).^2));

            if (distance < minDist)
                minDist = distance;
                minIndex = i;
            end
        end
    end

    if (minDist ~= inf)
        infoText = {['Filopodium ID: ' num2str(settings.currentFilopodia{settings.currentImage}(minIndex).id)], ...
                    ['Cell ID: ' num2str(settings.currentFilopodia{settings.currentImage}(minIndex).cellId)], ...
                    ['Length: ' num2str(settings.currentFilopodia{settings.currentImage}(minIndex).length*settings.pixelToMicrons) 'µm (' num2str(settings.currentFilopodia{settings.currentImage}(minIndex).length) 'px)'], ...
                    ['RFP Intensity: ' num2str(settings.currentFilopodia{settings.currentImage}(minIndex).rfpIntensity)], ...
                    ['GFP Intensity: ' num2str(settings.currentFilopodia{settings.currentImage}(minIndex).gfpIntensity)], ...
                    ['Wnt Positive: ' num2str(settings.currentFilopodia{settings.currentImage}(minIndex).gfpIntensity > settings.wntPositiveThreshold)]};
        
        helpdlg(infoText);
    end
    
elseif (strcmp(evt.Character, 's'))
    %% select the region of interest
    h = imfreehand;
    if (~isempty(h))
        maskImage = createMask(h, settings.imageHandle);
        
        if (sum(maskImage(:)) > 3)
            for i=1:size(settings.endPoints{settings.currentImage},1)
                currentPosition = settings.endPoints{settings.currentImage}(i,settings.positionIndices);
                if (maskImage(currentPosition(2), currentPosition(1)) > 0)
                    settings.endPoints{settings.currentImage}(i,settings.selectionIndex) = settings.currentCell{settings.currentImage};
                    settings.selectedEndPoints{settings.currentImage} = [settings.selectedEndPoints{settings.currentImage}; settings.endPoints{settings.currentImage}(i,:)];
                end
            end
        else
            clickPosition = get(gca, 'currentpoint');
            clickPosition = round(clickPosition(1,1:2))
            minDist = inf;
            minIndex = 1;
            for i=1:size(settings.endPoints{settings.currentImage})
                distance = sqrt(sum((settings.endPoints{settings.currentImage}(i,3:4) - clickPosition).^2));
                
                if (distance < minDist)
                    minDist = distance;
                    minIndex = i;
                end
            end
            
            if (minDist < settings.meanIntensityWindowSize)
                settings.endPoints{settings.currentImage}(minIndex,settings.selectionIndex) = settings.currentCell{settings.currentImage};
                settings.selectedEndPoints{settings.currentImage} = [settings.selectedEndPoints{settings.currentImage}; settings.endPoints{settings.currentImage}(minIndex,:)];
            end
        end
        if (settings.autoUpdate == true)
            TraceFilopodia;
        else
            UpdateVisualization;
        end
    end
    
elseif (strcmp(evt.Character, 'n'))
    h = impoly('Closed', false);
    DrawManualFilopodium;
    
elseif (strcmp(evt.Character, 'm'))
    h = imfreehand('Closed', false);
    DrawManualFilopodium;
elseif (strcmp(evt.Character, 'o'))
    % Construct a questdlg with three options
    choice = questdlg('Would you like to save the project before opening the new project?', ...
        'Save before exiting?', ...
        'Yes','No','Cancel','Cancel');
    % Handle response
    switch choice
        case 'Yes'
            saveProject;
        case 'No'
            
        case 'Cancel'
            return;
    end
    set(settings.mainFigure, 'CloseRequestFcn', '');
    delete(settings.mainFigure);
    FilopodiaSegmentationGUI;
elseif (strcmp(evt.Character, 'u'))
    settings.autoUpdate = ~settings.autoUpdate;
elseif (strcmp(evt.Character, 'p'))
    settings.projectSettings = inputdlg({'Pixel Size (microns):', 'Scale Bar Size (microns):', 'Scale Offset X (% Width):', 'Scale Bar Offset Y (% Height):', 'Wnt Threshold:', 'Wnt Threshold Step:'},...
        'Project Settings', [1 50; 1 50; 1 50; 1 50; 1 50; 1 50], {num2str(settings.pixelToMicrons), num2str(settings.scaleBarSize), num2str(settings.scaleBarOffset(1)), num2str(settings.scaleBarOffset(2)), num2str(settings.wntPositiveThreshold), num2str(settings.wntThresholdStep)});
    
    if (~isempty(settings.projectSettings))
        settings.pixelToMicrons = str2double(settings.projectSettings{1});
        settings.scaleBarSize = str2double(settings.projectSettings{2});
        settings.scaleBarOffset = [str2double(settings.projectSettings{3}), str2double(settings.projectSettings{4})];
        settings.wntPositiveThreshold = str2double(settings.projectSettings{5});
        settings.wntThresholdStep = str2double(settings.projectSettings{6});
        UpdateVisualization;
    end
elseif (strcmp(evt.Character, 'q'))
    %% select the region of interest
    h = imfreehand;
    if (~isempty(h))
        maskImage = createMask(h, settings.imageHandle);
        somaLabelImage = bwlabel(settings.somaImage{settings.currentImage});
        replaceLabel = max(somaLabelImage(maskImage>0));
        
        deletionIndices = [];
        for i=1:size(settings.perimeterPoints{settings.currentImage},1)
            if (somaLabelImage(settings.perimeterPoints{settings.currentImage}(i,4), settings.perimeterPoints{settings.currentImage}(i,3)) == replaceLabel || ...
                    settings.perimeterPoints{settings.currentImage}(i,settings.selectionIndex) == settings.currentCell{settings.currentImage})
                deletionIndices = [deletionIndices; i];
            end
        end
        
        somaLabelImage(somaLabelImage == replaceLabel) = 0;
        somaLabelImage(maskImage > 0) = 1;
        settings.somaImage{settings.currentImage} = somaLabelImage > 0;
        
        settings.perimeterImage{settings.currentImage} = bwperim(settings.somaImage{settings.currentImage});
        maskPerimeterImage = bwperim(maskImage);
        settings.perimeterPoints{settings.currentImage}(deletionIndices,:) = [];
        [additionalPointsY, additionalPointsX] = ind2sub(size(settings.perimeterImage{settings.currentImage}), find(maskPerimeterImage > 0));
        settings.perimeterPoints{settings.currentImage} = [settings.perimeterPoints{settings.currentImage}; zeros(size(additionalPointsX,1),2), additionalPointsX, additionalPointsY, zeros(size(additionalPointsX)), zeros(size(additionalPointsX,1),2), settings.currentCell{settings.currentImage}*ones(size(additionalPointsX))];
    end
    UpdateVisualization;
elseif (strcmp(evt.Character, 'r'))
    
    %% select the region of interest
    h = imfreehand;
    if (~isempty(h))
        maskImage = createMask(h, settings.imageHandle);
        axisRange = [inf,0,inf,0];
        for i=1:size(settings.endPoints{settings.currentImage},1)
            currentPosition = settings.endPoints{settings.currentImage}(i,settings.positionIndices);
            if (maskImage(currentPosition(2), currentPosition(1)) > 0)
                settings.endPoints{settings.currentImage}(i,settings.selectionIndex) = settings.currentCell{settings.currentImage};
                settings.selectedEndPoints{settings.currentImage} = [settings.selectedEndPoints{settings.currentImage}; settings.endPoints{settings.currentImage}(i,:)];
                %                     axisRange = [min(settings.endPoints{settings.currentImage}(i,settings.positionIndices(1)), axisRange(1)), ...
                %                         max(settings.endPoints{settings.currentImage}(i,settings.positionIndices(1)), axisRange(2)), ...
                %                         min(settings.endPoints{settings.currentImage}(i,settings.positionIndices(2)), axisRange(3)), ...
                %                         max(settings.endPoints{settings.currentImage}(i,settings.positionIndices(2)), axisRange(4))];
            end
        end
        for i=1:size(settings.perimeterPoints{settings.currentImage},1)
            currentPosition = settings.perimeterPoints{settings.currentImage}(i,settings.positionIndices);
            if (maskImage(currentPosition(2), currentPosition(1)) > 0)
                settings.perimeterPoints{settings.currentImage}(i,settings.selectionIndex) = settings.currentCell{settings.currentImage};
                %                     axisRange = [min(settings.perimeterPoints{settings.currentImage}(i,settings.positionIndices(1)), axisRange(1)), ...
                %                         max(settings.perimeterPoints{settings.currentImage}(i,settings.positionIndices(1)), axisRange(2)), ...
                %                         min(settings.perimeterPoints{settings.currentImage}(i,settings.positionIndices(2)), axisRange(3)), ...
                %                         max(settings.perimeterPoints{settings.currentImage}(i,settings.positionIndices(2)), axisRange(4))];
            else
                if (settings.perimeterPoints{settings.currentImage}(i,settings.selectionIndex) == settings.currentCell{settings.currentImage})
                    settings.perimeterPoints{settings.currentImage}(i,settings.selectionIndex) = 0;
                end
            end
        end
        %settings.axisRange = axisRange + [-10, 10, -10, 10];
        if (settings.autoUpdate == true)
            TraceFilopodia;
        else
            UpdateVisualization;
        end
    end
elseif (strcmp(evt.Character, 'x'))
    %% switch between equal axis spacing or stretched
    settings.axesEqual = ~settings.axesEqual;
    UpdateVisualization;
elseif (strcmp(evt.Character, 'h'))
    %% show the help dialog
    ShowHelp;
elseif (strcmp(evt.Character, 'w'))
    %% show the coexpression plot
    ShowCoexpression;
elseif (strcmp(evt.Character, '1') || strcmp(evt.Character, '2') || strcmp(evt.Character, '3') || strcmp(evt.Character, '4') || strcmp(evt.Character, '5') || strcmp(evt.Character, '6'))
    %% show single-view GFP image
    settings.singleViewId = str2double(evt.Character);
    settings.singleView = true;
    axes(settings.rfpAxes); cla;
    UpdateVisualization;
elseif (strcmp(evt.Key, 'space'))
    pan on;
elseif (strcmp(evt.Character, 'e'))
    TraceFilopodia;
elseif (strcmp(evt.Character, 'c'))
    settings.colormapId = max(1, min(8, settings.colormapId-1));
    UpdateVisualization;
elseif (strcmp(evt.Character, 'v'))
    settings.colormapId = max(1, min(8, settings.colormapId+1));
    UpdateVisualization;
end
end