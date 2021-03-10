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

function MouseDown(~, ~)

%% get global variables
global settings;

%% get current modifier keys
modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
shiftPressed = ismember('shift',modifiers);
ctrlPressed = ismember('control',modifiers);
currentButton = get(gcbf, 'SelectionType');
clickPosition = get(gca, 'currentpoint');
clickPosition = [clickPosition(1,1), clickPosition(1,2)];
if (strcmp(currentButton, 'open'))
    settings.clickType = 'open';
elseif (strcmp(currentButton, 'normal'))
    settings.clickType = 'normal';
elseif (strcmp(currentButton, 'extend'))
    settings.clickType = 'extend';
else
    currentButton = settings.clickType;
end

if (ctrlPressed == true && strcmp(settings.clickType, 'open'))
    pan on;
end

if (shiftPressed == true)
    if (isempty(settings.filopodiaStart) == true)
        %% set the start position
        settings.filopodiaStart = [clickPosition, settings.currentSlice];
        disp(['Start Position set to ' num2str([clickPosition, settings.currentSlice])]);
    elseif (isempty(settings.filopodiaEnd) == true)
        %% set the end position
        settings.filopodiaEnd = [clickPosition, settings.currentSlice];
        
        %% identify the filopodia on the maximum projection from min to max z
        projectionRange = min(settings.currentSlice, settings.filopodiaStart(3)):max(settings.currentSlice, settings.filopodiaStart(3));
        dFgMaxProj = fLiveWireGetCostFcn(max(squeeze(settings.edgeImage(:,:,projectionRange)), [], 3));
        [iPX, iPY] = fLiveWireCalcP(dFgMaxProj, settings.filopodiaStart(1), settings.filopodiaStart(2), ceil(norm(settings.filopodiaEnd-settings.filopodiaStart)));
        [iXPath, iYPath] = fLiveWireGetPath(iPX, iPY, settings.filopodiaEnd(1), settings.filopodiaEnd(2));
        
        %% handle the identified path
        if (isempty(iXPath))
            disp('Failed to trace filopodia, please try again with a slightly different start+end point or use the free-hand segmentation tool.');
            
            choice = questdlg('Failed to trace filopodia. Use direct connection?', ...
                              'Failed to trace filopodia?', ...
                              'Yes','No','No');

            %% try to load a project file
            if (strcmp(choice, 'Yes') == true)
                [iXPath, iYPath] = bresenham(settings.filopodiaStart(1), settings.filopodiaStart(2), settings.filopodiaEnd(1), settings.filopodiaEnd(2));
            else
                %% clear the filopodia extents
                settings.filopodiaStart = [];
                settings.filopodiaEnd = [];
                settings.dirtyFlag = true;
                updateVisualization;
                return;
            end
        end
        
        %% automatically determine the z-path
        xzImage = zeros(length(iXPath), size(settings.edgeImage, 3));
        for i=1:length(iXPath)
            xzImage(i,:) = squeeze(settings.edgeImage(iYPath(i), iXPath(i),:));
        end

        %% identify the z-path
        dFgMaxProj = fLiveWireGetCostFcn(xzImage');
        [iPX, iPY] = fLiveWireCalcP(dFgMaxProj, 1, settings.filopodiaStart(3), length(iXPath));
        [iXPathStretched, iZPath] = fLiveWireGetPath(iPX, iPY, length(iXPath), settings.filopodiaEnd(3));
        iXPath = [settings.filopodiaStart(1); iXPath(iXPathStretched)];
        iYPath = [settings.filopodiaStart(2); iYPath(iXPathStretched)];
        iZPath = [settings.filopodiaStart(3); iZPath];

        %% setup the result object
        currentFilopodia = length(settings.segmentedFilopodia)+1;
        settings.segmentedFilopodia(currentFilopodia).id = currentFilopodia;
        settings.segmentedFilopodia(currentFilopodia).cellId = settings.currentCell;
        settings.segmentedFilopodia(currentFilopodia).positions = double([iXPath, iYPath, iZPath]);
        settings.segmentedFilopodia(currentFilopodia).start = settings.filopodiaStart;
        settings.segmentedFilopodia(currentFilopodia).end = settings.filopodiaEnd;
        settings.segmentedFilopodia(currentFilopodia).wntPositive = 0;
        settings.segmentedFilopodia(currentFilopodia).length = 0;
        settings.segmentedFilopodia(currentFilopodia).lengthVoxel = length(iXPath);
        scaledPositions = double([iXPath*settings.xscale, iYPath*settings.yscale, iZPath*settings.zscale]);
        for i=2:length(iXPath)
            settings.segmentedFilopodia(currentFilopodia).length = settings.segmentedFilopodia(currentFilopodia).length + norm(scaledPositions(i,:) - scaledPositions(i-1,:));
        end

        %% select the latest filopodia
        settings.dirtyFlag = true;
        settings.selectedFilopodia = length(settings.segmentedFilopodia);

        %% clear the filopodia extents
        settings.filopodiaStart = [];
        settings.filopodiaEnd = [];
    end
end

%% update the visualization
UpdateVisualization;

end