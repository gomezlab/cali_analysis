function cleaned_mask=clean_up_cell_mask(cell_mask)

labeled_mask = bwlabel(cell_mask,4);

areas = regionprops(labeled_mask,'Area');

cleaned_mask = ismember(labeled_mask, find([areas.Area] == max([areas.Area])));

cleaned_mask = imfill(cleaned_mask,'holes');

end