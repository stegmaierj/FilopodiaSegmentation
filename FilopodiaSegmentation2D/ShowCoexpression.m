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
numCells = size(settings.currentFilopodia{settings.currentImage},1);
lengths = [];
figure; hold on;
for j=1:numCells
    numFilopodia = size(settings.currentFilopodia{settings.currentImage},2);
    
    %% continue if no filopodia were extracted yet.
    if (isempty(fieldnames(settings.currentFilopodia{settings.currentImage})))
        continue;
    end
    
    for k=1:numFilopodia
        if (~isempty(settings.currentFilopodia{settings.currentImage}(j,k).positions))
            plot(settings.currentFilopodia{settings.currentImage}(j,k).rfpIntensity, ...
                    settings.currentFilopodia{settings.currentImage}(j,k).gfpIntensity, 'og');
                
            plot(settings.currentFilopodia{settings.currentImage}(j,k).rfpIntensity, ...
                    settings.currentFilopodia{settings.currentImage}(j,k).gfpIntensity, '.k');
                
            lengths = [lengths; settings.currentFilopodia{settings.currentImage}(j,k).length];
        end
    end
end
xlabel('RFP Intensity (a.u.)');
ylabel('GFP Intensity (a.u.)');

figure; hold on;
for j=1:numCells
    numFilopodia = size(settings.currentFilopodia{settings.currentImage},2);
    
    %% continue if no filopodia were extracted yet.
    if (isempty(fieldnames(settings.currentFilopodia{settings.currentImage})))
        continue;
    end
    
    for k=1:numFilopodia
        if (~isempty(settings.currentFilopodia{settings.currentImage}(j,k).positions))
            plot(settings.currentFilopodia{settings.currentImage}(j,k).length, ...
                    settings.currentFilopodia{settings.currentImage}(j,k).gfpIntensity, 'og');
                
            plot(settings.currentFilopodia{settings.currentImage}(j,k).length, ...
                    settings.currentFilopodia{settings.currentImage}(j,k).gfpIntensity, '.k');
        end
    end
end
xlabel('Length (px)');
ylabel('GFP Intensity (a.u.)');

figure;
hist(lengths);
xlabel('Length (px)');
ylabel('Number of Filopodia');