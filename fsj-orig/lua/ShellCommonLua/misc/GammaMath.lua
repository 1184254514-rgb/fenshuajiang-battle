--region GammaMath.lua
--Date 2015-12-14

-----------------------------------------------
-- CVector3f
-----------------------------------------------
function CVector3f:Ctor( x, y, z )
	x = x and self:x( x );
	y = y and self:y( y );
	z = z and self:z( z );
end

function CVector3f:Zero()
    self:x( 0 );
    self:y( 0 );
    self:z( 0 );
end

function CVector2f:GetXYZ()
	return self:x(), self:y(), self:z();
end

function CVector3f:Clone()
	return CVector3f:new( self:x(), self:y(), self:z() );
end

-----------------------------------------------
-- CVector2f
-----------------------------------------------
function CVector2f:Ctor( x, y )
	x = x and self:x( x );
	y = y and self:y( y );
end

function CVector2f:Zero()
    self:x( 0 );
    self:y( 0 );
end

function CVector2f:GetXY()
	return self:x(), self:y();
end

function CVector2f:Clone()
	return CVector2f:new( self:x(), self:y() );
end

-----------------------------------------------
-- CDir
-----------------------------------------------
function CDir:Ctor( uDir )
	uDir = uDir and self:uDir( uDir );
end

function CDir:Clone()
	return CDir:new( self:uDir() );
end

-----------------------------------------------
-- CFRect
-----------------------------------------------
function CFRect:Ctor( left, top, right, bottom )
	left = left and self:left( left );
	top = top and self:top( top );
	right = right and self:right( right );
	bottom = bottom and self:bottom( bottom );
end


-----------------------------------------------
-- CIRect
-----------------------------------------------
function CIRect:Ctor( left, top, right, bottom )
	left = left and self:left( left );
	top = top and self:top( top );
	right = right and self:right( right );
	bottom = bottom and self:bottom( bottom );
end

-----------------------------------------------
-- CMatrix
-----------------------------------------------
function CMatrix:Clone()
	return CMatrix:new( self );
end

-----------------------------------------------
-- Algorithm
-----------------------------------------------
function Quadratic(a,b,c)
   local a2 = 2*a;
   local d = math.sqrt(b^2 - 4*a*c);
   x1 = (-b + d)/a2;
   --x2 = (-b - d)/a2;
   return x1--, x2;
end
--endregion
