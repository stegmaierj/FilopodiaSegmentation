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

helpText = {'1,2,3,4: Switch view between GFP/RFP/Hessian/Skeleton Images', ...
            'A: Add a new filopodia tip if a detection is missing', ...
            'D: De-select a single filopodia tip or filopodia tips in a region', ...
            'E: Extract all currently selected filopodia and trace the tips to the soma', ...
            'G: Save the project and filopodia statistics to disk', ...
            'I: Allows to select a filopodium tip and shows the properties', ...
            'N: Manually draw a filopodium using line segments (double-click to finish)', ...
            'M: Manually draw a filopodium in free hand mode', ...
            'P: Open propeties dialog to adjust the scale bar size, location and units', ...
            'Q: Manually re-draw the soma boundaries if the automatic detection is erroneous', ...
            'R: Select the region of interest, i.e., a cell and all its filopodia that should be counted', ...
            'S: Select a single filopodia tip or filopodia tips in a region', ...
            'O: Open different image or another project (folder containing tiff files to start a new project or *.mat to open an existing project)', ...
            'U: Toggles auto update. If enabled, each change causes an update of the filopodia (e.g. after roi selection/tip selection/tip deselection)', ...
            'W: Show the Wnt expression of the selected filopodia in a scatter plot', ...
            'C/V: Show previous/next colormap', ...
            'X: Toggles aspect ratio of the image (original aspect ratio / stretched to the window size)', ...
            '+/-: Increase/decrease the cluster radius to merge close filopodia tips (Perform this as the first step, even before ROI selection).', ...
            './,: Increase/decrease the wnt threshold. Tips with a GFP value larger than this theshold will be counted as wnt positive / cytonemes.', ...
            'Arrow Up/Arrow Down: Increase/decrease the cell counter.', ...
            'Left Arrow: Decrease image id (to navigate between different images of a project)', ...
            'Right Arrow: Increase image id (to navigate between different images of a project)', ...
            'Wheel: Scroll through the slices of the stack', ...
            'CTRL+Wheel: Increase/decrease zoom', ...
            '', ...
            'Hint: In case key presses show no effect, left click once on the image and try hitting the button again. This only happens if the window looses the focus.'};

helpdlg(helpText);