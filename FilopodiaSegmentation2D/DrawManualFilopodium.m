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

if (~isempty(h))
    pos = getPosition(h);
    
    %% calculate the current centroid
    selectedPerimeterIndices = settings.perimeterPoints{settings.currentImage}(:,settings.selectionIndex) == settings.currentCell{settings.currentImage};
    currentCentroid = round([mean(settings.perimeterPoints{settings.currentImage}(selectedPerimeterIndices,3)), mean(settings.perimeterPoints{settings.currentImage}(selectedPerimeterIndices,4))]);
    
    if (norm(currentCentroid - pos(1,:)) < norm(currentCentroid - pos(end,:)))
        iXPath = round(pos(:,1));
        iYPath = round(pos(:,2));
    else
        iXPath = flipud(round(pos(:,1)));
        iYPath = flipud(round(pos(:,2)));
    end
    
    currentFilopodiumId = size(settings.currentFilopodia{settings.currentImage},2)+1;
    settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).id = currentFilopodiumId;
    settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).cellId = settings.currentCell{settings.currentImage};
    settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).positions = [iXPath, iYPath];
    settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).length = ComputeFilopodiaLength(iXPath, iYPath);
    rangeX = max(1, round(iXPath(end) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},1), round(iXPath(end) + settings.meanIntensityWindowSize));
    rangeY = max(1, round(iYPath(end) - settings.meanIntensityWindowSize)):min(size(settings.gfpImage{settings.currentImage},2), round(iYPath(end) + settings.meanIntensityWindowSize));
    tmpImageGFP = settings.gfpImage{settings.currentImage}(rangeY, rangeX);
    tmpImageRFP = settings.rfpImage{settings.currentImage}(rangeY, rangeX);
    settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).gfpIntensity = mean(tmpImageGFP(:));
    settings.currentFilopodia{settings.currentImage}(currentFilopodiumId).rfpIntensity = mean(tmpImageRFP(:));
end
settings.selectedEndPoints{settings.currentImage} = [settings.selectedEndPoints{settings.currentImage}; currentFilopodiumId, 0, iXPath(end), iYPath(end), 0, 0, 0, -settings.currentCell{settings.currentImage}];
UpdateVisualization;