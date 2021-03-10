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

global settings;

settings.selectedEndPoints{settings.currentImage} = unique(settings.selectedEndPoints{settings.currentImage}, 'rows');

%% loop through the current filopodia and delete them if no selected end point is present
deletionIndices = [];
for i=1:length(settings.currentFilopodia{settings.currentImage})
    if (~isfield(settings.currentFilopodia{settings.currentImage}, 'id') || isempty(settings.currentFilopodia{settings.currentImage}(i).id))
        continue;
    end
    
    endPointFound = false;
    for j=1:size(settings.selectedEndPoints{settings.currentImage},1)
        if (settings.currentFilopodia{settings.currentImage}(i).positions(end,1) == settings.selectedEndPoints{settings.currentImage}(j,3) && ...
            settings.currentFilopodia{settings.currentImage}(i).positions(end,2) == settings.selectedEndPoints{settings.currentImage}(j,4))
            endPointFound = true;
            break;
        end
    end
    
    if (endPointFound == false)
        deletionIndices = [deletionIndices, i];
    end
end
settings.currentFilopodia{settings.currentImage}(deletionIndices) = [];

validEndPointIndices = [];
for i=1:size(settings.selectedEndPoints{settings.currentImage},1)
    
    %% check if it's a manual filopodium or if it belongs to a different cell
    if (settings.selectedEndPoints{settings.currentImage}(i,settings.selectionIndex) < 0 || abs(settings.selectedEndPoints{settings.currentImage}(i,settings.selectionIndex)) ~= settings.currentCell{settings.currentImage})
        continue;
    end
    
    %% check if the filopodium already exists
    extractFilopodium = true;
    for j=1:length(settings.currentFilopodia{settings.currentImage})
        if (~isfield(settings.currentFilopodia{settings.currentImage}, 'id') || isempty(settings.currentFilopodia{settings.currentImage}(j).id))
            continue;
        end
        
        if (settings.currentFilopodia{settings.currentImage}(j).positions(end,1) == settings.selectedEndPoints{settings.currentImage}(i,3) && ...
            settings.currentFilopodia{settings.currentImage}(j).positions(end,2) == settings.selectedEndPoints{settings.currentImage}(i,4))
            extractFilopodium = false;
            break;
        end
    end
    
    if (extractFilopodium == true)
        validEndPointIndices = [validEndPointIndices, i];
    end
end

%% extract the remaining filopodia
deletionIndices = [];
if (~isempty(validEndPointIndices))
    
    %% calculate the current centroid
    selectedPerimeterIndices = settings.perimeterPoints{settings.currentImage}(:,settings.selectionIndex) == settings.currentCell{settings.currentImage};
    currentCentroid = round([mean(settings.perimeterPoints{settings.currentImage}(selectedPerimeterIndices,3)), mean(settings.perimeterPoints{settings.currentImage}(selectedPerimeterIndices,4))]);
    
    maxDistance = 0;
    for i=validEndPointIndices
        currentDistance = ceil(norm(settings.selectedEndPoints{settings.currentImage}(i,settings.positionIndices(1:2)) - currentCentroid));
        if (currentDistance > maxDistance)
            maxDistance = currentDistance;
        end
    end
    
    %costImage = fLiveWireGetCostFcn(imadjust(settings.objectnessImage{settings.currentImage}));
    costImage = fLiveWireGetCostFcn(imadjust(0.5*settings.objectnessImage{settings.currentImage}) + 0.5*imadjust(settings.rfpImage{settings.currentImage}));
    [iPX, iPY] = fLiveWireCalcP(costImage, currentCentroid(1), currentCentroid(2), maxDistance);
    currentFilopodiumId = length(settings.currentFilopodia{settings.currentImage});
    
    for i=validEndPointIndices
        
        currentFilopodiumId = length(settings.currentFilopodia{settings.currentImage})+1;
        for j=1:length(settings.currentFilopodia{settings.currentImage})
            if (~isfield(settings.currentFilopodia{settings.currentImage}, 'id') || isempty(settings.currentFilopodia{settings.currentImage}(j).id))
                currentFilopodiumId = j;
                break;
            end
        end
        
        %% calculate the cost image
        currentEndPoint = round(settings.selectedEndPoints{settings.currentImage}(i,settings.positionIndices(1:2)));
        
        %% get the live wire prediction
        [iXPath, iYPath] = fLiveWireGetPath(iPX, iPY, currentEndPoint(1), currentEndPoint(2));
        
        boundaryIntensity = zeros(length(iXPath), 1);
        for j=1:length(iXPath)
            boundaryIntensity(j) = settings.somaImage{settings.currentImage}(iYPath(j), iXPath(j));
        end
        
        maxBoundaryPosition = max(find(boundaryIntensity > 0));
        iXPath = iXPath(maxBoundaryPosition:end);
        iYPath = iYPath(maxBoundaryPosition:end);
        %plot(iXPath, iYPath, '-r');
        
        %% continue if no valid path was found
        if (length(iXPath) <= 1)
            deletionIndices = [deletionIndices, i];
            continue;
        else
            settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).id = currentFilopodiumId;
            settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).cellId = settings.currentCell{settings.currentImage};
            settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).positions = [iXPath, iYPath];
            settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).length = ComputeFilopodiaLength(iXPath, iYPath);
            
            rangeX = max(1, round(iXPath(end) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},2), floor(iXPath(end) + settings.meanIntensityWindowSize));
            rangeY = max(1, round(iYPath(end) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},1), floor(iYPath(end) + settings.meanIntensityWindowSize));
%             rangeX = iXPath(end);
%             rangeY = iYPath(end);
            tmpImageGFP = settings.gfpImage{settings.currentImage}(rangeY, rangeX);
            tmpImageRFP = settings.rfpImage{settings.currentImage}(rangeY, rangeX);
            settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).gfpIntensity = max(tmpImageGFP(:));
            settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).rfpIntensity = max(tmpImageRFP(:));
            currentFilopodiumId = currentFilopodiumId+1;
        end
    end
end
settings.selectedEndPoints{settings.currentImage}(deletionIndices,:) = [];

%% update the visualization
UpdateVisualization;

%%%%%%%%%%%%%%%% OLD %%%%%%%%%%%%%%

% validEndPoints = find(settings.endPoints{settings.currentImage}(:,settings.selectionIndex) == settings.currentCell{settings.currentImage});
%
% %% calculate the current centroid
% selectedPerimeterIndices = settings.perimeterPoints{settings.currentImage}(:,settings.selectionIndex) == settings.currentCell{settings.currentImage};
% currentCentroid = round([mean(settings.perimeterPoints{settings.currentImage}(selectedPerimeterIndices,3)), mean(settings.perimeterPoints{settings.currentImage}(selectedPerimeterIndices,4))]);
%
% maxDistance = 0;
% for i=validEndPoints'
%     currentDistance = ceil(norm(settings.endPoints{settings.currentImage}(i,settings.positionIndices(1:2)) - currentCentroid));
%     if (currentDistance > maxDistance)
%         maxDistance = currentDistance;
%     end
% end
%
% %costImage = fLiveWireGetCostFcn(imadjust(settings.objectnessImage{settings.currentImage}));
% costImage = fLiveWireGetCostFcn(imadjust(0.5*settings.objectnessImage{settings.currentImage}) + 0.5*imadjust(settings.rfpImage{settings.currentImage}));
% [iPX, iPY] = fLiveWireCalcP(costImage, currentCentroid(1), currentCentroid(2), maxDistance);
% currentFilopodiumId = 1;
% % currentFilopodia = settings.currentFilopodia{settings.currentImage};
% if (size(settings.currentFilopodia{settings.currentImage},1) >= settings.currentCell{settings.currentImage})
%     for i=1:size(settings.currentFilopodia{settings.currentImage},2)
%         settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage},i).id = [];
%         settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage},i).positions = [];
%         settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage},i).length = [];
%         settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage},i).gfpIntensity = [];
%         settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage},i).rfpIntensity = [];
%     end
% end
%
% if (size(settings.manualFilopodia{settings.currentImage},1) >= settings.currentCell{settings.currentImage})
%     for i=1:size(settings.manualFilopodia{settings.currentImage},2)
%
%         if (isfield(settings.manualFilopodia{settings.currentImage}, 'positions') && ~isempty(settings.manualFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, i).positions))
%             settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).id = currentFilopodiumId;
%             settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).positions = settings.manualFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, i).positions;
%             settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).length = settings.manualFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, i).length;
%             settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).gfpIntensity = settings.manualFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, i).gfpIntensity;
%             settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).rfpIntensity = settings.manualFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, i).rfpIntensity;
%             currentFilopodiumId = currentFilopodiumId+1;
%         end
%     end
% end
%
% for i=validEndPoints'
%     %% calculate the cost image
%     currentEndPoint = round(settings.endPoints{settings.currentImage}(i,settings.positionIndices(1:2)));
%
%     %% get the live wire prediction
%     [iXPath, iYPath] = fLiveWireGetPath(iPX, iPY, currentEndPoint(1), currentEndPoint(2));
%
%     boundaryIntensity = zeros(length(iXPath), 1);
%     for j=1:length(iXPath)
%        boundaryIntensity(j) = settings.somaImage{settings.currentImage}(iYPath(j), iXPath(j));
%     end
%
%     maxBoundaryPosition = max(find(boundaryIntensity > 0));
%     iXPath = iXPath(maxBoundaryPosition:end);
%     iYPath = iYPath(maxBoundaryPosition:end);
%     %plot(iXPath, iYPath, '-r');
%
%     %% continue if no valid path was found
%     if (length(iXPath) <= 1)
%         continue;
%     else
%        settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).id = currentFilopodiumId;
%        settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).positions = [iXPath, iYPath];
%        settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).length = ComputeFilopodiaLength(iXPath, iYPath);
%
%        rangeX = max(1, round(iXPath(end) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},2), floor(iXPath(end) + settings.meanIntensityWindowSize));
%        rangeY = max(1, round(iYPath(end) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},1), floor(iYPath(end) + settings.meanIntensityWindowSize));
%        tmpImageGFP = settings.gfpImage{settings.currentImage}(rangeY, rangeX);
%        tmpImageRFP = settings.rfpImage{settings.currentImage}(rangeY, rangeX);
%        settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).gfpIntensity = mean(tmpImageGFP(:));
%        settings.currentFilopodia{settings.currentImage}(settings.currentCell{settings.currentImage}, currentFilopodiumId).rfpIntensity = mean(tmpImageRFP(:));
%        currentFilopodiumId = currentFilopodiumId+1;
%     end
%     test = 1;
% end
% updateVisualization;
