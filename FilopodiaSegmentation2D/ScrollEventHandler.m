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

%% scroll event handler
function ScrollEventHandler(src,evnt)
    global settings;

    %% get the modifier keys
    modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
    shiftPressed = ismember('shift',modifiers);
    ctrlPressed = ismember('control',modifiers);
    altPressed = ismember('alt',modifiers);
    
    %% if control pressed increase/decrease the gfp contrast
    if (ctrlPressed == true)

        %% get the click position
        clickPosition = get(gca, 'currentpoint');
        clickPosition = [clickPosition(1,1), clickPosition(1,2)];

        figure(settings.mainFigure);
        oldXLim = get(gca, 'XLim');
        oldYLim = get(gca, 'YLim');

        %% identify wheel direction
        if evnt.VerticalScrollCount < 0
            newWidth(1) = clickPosition(1) - abs(clickPosition(1)-oldXLim(1))/2;
            newWidth(2) = clickPosition(1) + abs(clickPosition(1)-oldXLim(2))/2;
            newHeight(1) = clickPosition(2) - abs(clickPosition(2)-oldYLim(1))/2;
            newHeight(2) = clickPosition(2) + abs(clickPosition(2)-oldYLim(2))/2;
        else
            newWidth(1) = clickPosition(1) - abs(clickPosition(1)-oldXLim(1))*2;
            newWidth(2) = clickPosition(1) + abs(clickPosition(1)-oldXLim(2))*2;
            newHeight(1) = clickPosition(2) - abs(clickPosition(2)-oldYLim(1))*2;
            newHeight(2) = clickPosition(2) + abs(clickPosition(2)-oldYLim(2))*2;
        end

        newLimits = [newWidth(1) newWidth(2) newHeight(1) newHeight(2)];
        settings.axisRange = newLimits;
        
    %% if alt pressed increase/decrease the rfp contrast
    elseif (altPressed == true)
        stepSize = settings.stepRFPIntensity{settings.currentImage};
        if evnt.VerticalScrollCount > 0.0
            settings.maxRFPIntensity{settings.currentImage} = min(1, settings.maxRFPIntensity{settings.currentImage} + stepSize);
        elseif evnt.VerticalScrollCount < 0.0
            settings.maxRFPIntensity{settings.currentImage} = max(settings.minRFPIntensity{settings.currentImage}+stepSize, settings.maxRFPIntensity{settings.currentImage} - stepSize);
        end
    elseif (shiftPressed == true)
        stepSize = settings.stepBFIntensity{settings.currentImage};
        if evnt.VerticalScrollCount > 0.0
            settings.maxBFIntensity{settings.currentImage} = min(1, settings.maxBFIntensity{settings.currentImage} + stepSize);
        elseif evnt.VerticalScrollCount < 0.0
            settings.maxBFIntensity{settings.currentImage} = max(settings.minBFIntensity{settings.currentImage}+stepSize, settings.maxBFIntensity{settings.currentImage} - stepSize);
        end
        
    %% if no modifier is pressed perform scrolling through the stack
    else
        if evnt.VerticalScrollCount < 0.0
            settings.currentImage = settings.currentImage + 1;
        elseif evnt.VerticalScrollCount > 0.0
            settings.currentImage = settings.currentImage - 1;
        end
        settings.currentImage = max(min(length(settings.gfpImage), settings.currentImage), 1);
        resetAxis;
    end
    
    %% finally update the visualization
	UpdateVisualization;
end