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

function MouseUp(~, ~)

%% get global variables
global settings;

%% get current modifier keys
modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
shiftPressed = ismember('shift',modifiers);
ctrlPressed = ismember('control',modifiers);
altPressed = ismember('alt',modifiers);
currentButton = get(gcbf, 'SelectionType');
clickPosition = get(gca, 'currentpoint');
clickPosition = [clickPosition(1,1), clickPosition(1,2)];

%% add the click point as a positive or negative coexpression point including mean intensity calculations
if (ctrlPressed == true || altPressed == true)
    rangeX = max(1, round(clickPosition(1) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},1), round(clickPosition(1) + settings.meanIntensityWindowSize));
    rangeY = max(1, round(clickPosition(2) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},2), round(clickPosition(2) + settings.meanIntensityWindowSize));

    tmpImageGFP = settings.gfpImage{settings.currentImage}(rangeY, rangeX);
    tmpImageRFP = settings.rfpImage{settings.currentImage}(rangeY, rangeX);
    meanIntensityGFP = mean(tmpImageGFP(:));
    meanIntensityRFP = mean(tmpImageRFP(:));
end

if (ctrlPressed == true && altPressed == false)
    settings.resultTable{settings.currentImage} = [settings.resultTable{settings.currentImage}; ...
                                                   size(settings.resultTable,1), settings.meanIntensityWindowSize, clickPosition(1), clickPosition(2), settings.currentSlice, meanIntensityGFP, meanIntensityRFP, 1];
elseif (altPressed == true && ctrlPressed == false)
    settings.resultTable{settings.currentImage} = [settings.resultTable{settings.currentImage}; ...
                                                   size(settings.resultTable,1), settings.meanIntensityWindowSize, clickPosition(1), clickPosition(2), settings.currentSlice, meanIntensityGFP, meanIntensityRFP, 2];
elseif (altPressed == true && ctrlPressed == true)
    settings.resultTable{settings.currentImage} = [settings.resultTable{settings.currentImage}; ...
                                                   size(settings.resultTable,1), settings.meanIntensityWindowSize, clickPosition(1), clickPosition(2), settings.currentSlice, meanIntensityGFP, meanIntensityRFP, 3];
elseif (shiftPressed == true)
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
        settings.endPoints{settings.currentImage}(minIndex,settings.selectionIndex) = 0;
    end
end

%% update the visualization
updateVisualization;

end