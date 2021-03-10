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

function KeyRelease(hObject, eventdata, handles)



    global settings;
    
    %% assign the current cell id to the currently selected filopodium
    if (eventdata.Character == '+')
        settings.currentCell = settings.currentCell+1;
        UpdateVisualization;
    elseif (eventdata.Character == '-')
        settings.currentCell = max(1,settings.currentCell-1);
        UpdateVisualization;
    elseif (eventdata.Key == 'a')
        settings.segmentedFilopodia(settings.selectedFilopodia).cellId = settings.currentCell;
        UpdateVisualization;
    elseif (eventdata.Key == 'i')
        if (length(settings.segmentedFilopodia) <= 0)
            return;
        end
        
        currentPositions = settings.segmentedFilopodia(settings.selectedFilopodia).positions;
        settings.xLim = [min(currentPositions(:,1)), max(currentPositions(:,1))] + [-settings.previewPadding, settings.previewPadding];
        settings.yLim = [min(currentPositions(:,2)), max(currentPositions(:,2))] + [-settings.previewPadding, settings.previewPadding];
        settings.currentSlice = round(mean(currentPositions(:,3)));
        UpdateVisualization;
        
    elseif (eventdata.Key == 'd')
        if (settings.selectedFilopodia <= 0)
            return;
        end

        settings.segmentedFilopodia(settings.selectedFilopodia) = [];
        settings.selectedFilopodia = length(settings.segmentedFilopodia);
        settings.dirtyFlag = true;
        UpdateVisualization;
                
    elseif (eventdata.Key == 'm')
        settings.useMaximumProjection = ~settings.useMaximumProjection;
    elseif (eventdata.Key == 'n')

        choice = questdlg('Would you like to save the current project?', 'Save Project?', 'Yes', 'No','Cancel', 'Yes');
        if (strcmp(choice, 'Yes'))
            SaveProject();
        elseif (strcmp(choice, 'No'))
            FilopodiaSegmentation3D;
        end

    elseif (strcmp(eventdata.Key, 'alt'))
        if (length(settings.segmentedFilopodia) <= 0)
            return;
        end

        %% get an input coordinate and select the closest filopodium
        [x,y] = ginput(1);
        minDistance = inf;
        minIndex = 0;
        for i=1:length(settings.segmentedFilopodia)
            filopodiaCentroid = mean(settings.segmentedFilopodia(i).positions);
            clickPositionDistance = norm([x,y,settings.currentSlice] - filopodiaCentroid );
            if (clickPositionDistance < minDistance)
                minDistance = clickPositionDistance;
                minIndex = i;
            end
        end
        settings.selectedFilopodia = minIndex;
        settings.dirtyFlag = true;
        UpdateVisualization;
    elseif (strcmp(eventdata.Key, 'space'))
        pan on;
    elseif (eventdata.Key == 's')
        SaveProject();

    elseif (eventdata.Key == 'h')
        h = msgbox({'+/-: Increase/Decrease the current cell id (filopodia belonging to different cells are saved to different tables)' ...
                    'A: Assign current cell id to the currently selected filopodia' ...            
                    'D: Delete currently selected filopodia' ...
                    'E: Export data to an Excel spreadsheet' ...
                    'H: Displays this help dialog' ...
                    'I: Zoom to the currently selected filopodia' ...
                    'M: Maximum projection mode. If you scroll while drawing a filopodium, maximum projections of the slices will be generated to assist hitting the right point in a separate plane.' ...
                    'N: Create new project (be sure to save your current project before!)' ...
                    'O: Zoom out to the default view' ...
                    'R: Revert the direction of the currently selected filopodia' ...
                    'S: Save the current project and a csv table with the current results' ...
                    'W: Toggles the Wnt-Positive flag of the currently selected filopodia' ...
                    'ALT+Click: Selects the filopodia that is closest to the cursor' ...
                    'CTRL+S: Save the current project with a new project file name' ...
                    'CTRL+Wheel: Zoom in/out using a Google maps-like behavior' ...
                    'SHIFT+Click: Start/end a new filopodia trace (SHIFT+Click once at both ends of the filopodia)' ...
                    'Space: Enables the pan mode to move the main segmentation window' ...
                    'Wheel: Scroll through the slices of the stack'});

    elseif (eventdata.Key == 'w')
        if (length(settings.segmentedFilopodia) <= 0)
            return;
        end

        settings.segmentedFilopodia(settings.selectedFilopodia).wntPositive = ~settings.segmentedFilopodia(settings.selectedFilopodia).wntPositive;
        settings.dirtyFlag = true;
        UpdateVisualization;

    elseif (eventdata.Key == 'r')
        if (length(settings.segmentedFilopodia) <= 0)
            return;
        end

        settings.segmentedFilopodia(settings.selectedFilopodia).positions = flipud(settings.segmentedFilopodia(settings.selectedFilopodia).positions);
        settings.dirtyFlag = true;
        UpdateVisualization;

    elseif (eventdata.Key == 'o')

        settings.xLim = [1, size(settings.rawImage,1)];
        settings.yLim = [1, size(settings.rawImage,2)];
        UpdateVisualization;

    elseif (strcmp(eventdata.Key, 'uparrow') == 1 || strcmp(eventdata.Key, 'downarrow') == 1)
        if (length(settings.segmentedFilopodia) > 0)
            direction = 1;
            if (strcmp(eventdata.Key, 'downarrow') == 1)
                direction = -1;
            end
            settings.selectedFilopodia = min(max(1, settings.selectedFilopodia+direction), length(settings.segmentedFilopodia));
            settings.currentSlice = round(mean(settings.segmentedFilopodia(settings.selectedFilopodia).positions(:,3)));
            settings.dirtyFlag = true;
            UpdateVisualization;
        end
    elseif (strcmp(eventdata.Key, 'leftarrow') == 1)
        settings.currentSlice = settings.currentSlice - 1;
        settings.currentSlice = min(max(1,settings.currentSlice), size(settings.rawImage,3));
        UpdateVisualization;
    elseif (strcmp(eventdata.Key, 'rightarrow') == 1)
        settings.currentSlice = settings.currentSlice + 1;
        settings.currentSlice = min(max(1,settings.currentSlice), size(settings.rawImage,3));
        UpdateVisualization;
    end
end

function [] = SaveProject()

    %% get current modifier keys
    modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
    shiftPressed = ismember('shift',modifiers);
    ctrlPressed = ismember('control',modifiers);

    global settings;
    tmpSettings = settings;
    settings.edgeImage = [];
    settings.rawImage = [];
    settings.wntImage = [];
    settings.mainFigure = [];
    settings.closeupXYAxes = [];
    settings.closeupZAxes = [];
    settings.statsAxes = [];
    settings.mainAxes = [];
    if (isempty(settings.savePath) || ctrlPressed == true)
        [file,folder] = uiputfile('myproject.mat','Save file name', '*.mat');
        tmpSettings.savePath = [folder file];
        settings.savePath = [folder file];
    end
    if (settings.savePath ~= 0)
        save(tmpSettings.savePath, '-struct', 'settings');

        %% export the current information to a human readible format
        resultTable = [];
        for i=1:length(settings.segmentedFilopodia)
            currentFilopodia = settings.segmentedFilopodia(i);
            resultTable = [resultTable; i, currentFilopodia.cellId, currentFilopodia.start, currentFilopodia.end, currentFilopodia.length, currentFilopodia.wntPositive];
        end
                
        resultTable = sortrows(resultTable, size(resultTable, 2));
        dlmwrite(strrep(tmpSettings.savePath, '.mat', '.csv'), resultTable, ';');
        prepend2file('id; cellId; startXPos; startYPos; startZPos; endXPos; endYPos; endZPos; length; wntPositive;', strrep(tmpSettings.savePath, '.mat', '.csv'), 1);

        cellIds = unique(resultTable(:,2));
        resultLabels = {'id', 'cellId', 'startXPos', 'startYPos', 'startZPos', 'endXPos', 'endYPos', 'endZPos', 'length', 'wntPositive'};
        for i=cellIds'            
            outPath = strrep(tmpSettings.savePath, '.mat', '_Excel.xls');
            outSheet = 1;
            if (settings.useSingleResultFile == false)
                outPath = strrep(tmpSettings.savePath, '.mat', ['_Cell' num2str(i) '.xls']);
            else
                outSheet = i;
            end
            xlswrite(outPath, resultLabels, outSheet, 'A1');
            
            currentFilopodiaIds = resultTable(:,2) == i;
            currentFilopodia = resultTable(currentFilopodiaIds, :);
            xlswrite(outPath, num2cell(currentFilopodia), outSheet, 'A2');
        end
        
        disp(['Successfully saved the project to ' tmpSettings.savePath]);
    else
        disp('Failed to save the project! Please try again.');
    end

    settings = tmpSettings;
    clear tmpSettings;
end