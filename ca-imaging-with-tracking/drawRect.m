%Draws bounding box of object, with an integer modifier to increase/decrease the size of the bounding box 
function rect = drawRect(object, modifier)

bwbounds = bwboundaries(object);
xy = bwbounds{1};
x = xy(:, 1);
y = xy(:, 2);
top = min(x);
bottom = max(x);
left = min(y);
right = max(y);
rect=object;
for w=top-modifier:bottom+modifier
    for q=left-modifier:right+modifier
        rect(w,q)=1;
    end
end