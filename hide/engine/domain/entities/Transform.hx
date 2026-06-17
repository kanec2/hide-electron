// hide/domain/entities/Transform.hx
package hide.engine.domain.entities;

/**
Значение-объект (Value Object). Неизменяемый.
Для изменения — создаём новый экземпляр.
*/
class Transform {
    public final x:Float;
    public final y:Float;
    public final z:Float;
    public final rotX:Float;
    public final rotY:Float;
    public final rotZ:Float;
    public final scaleX:Float;
    public final scaleY:Float;
    public final scaleZ:Float;

    public function new(
        x:Float = 0, y:Float = 0, z:Float = 0,
        rotX:Float = 0, rotY:Float = 0, rotZ:Float = 0,
        scaleX:Float = 1, scaleY:Float = 1, scaleZ:Float = 1
    ) {
        this.x = x; this.y = y; this.z = z;
        this.rotX = rotX; this.rotY = rotY; this.rotZ = rotZ;
        this.scaleX = scaleX; this.scaleY = scaleY; this.scaleZ = scaleZ;
    }

    public function withPosition(x:Float, y:Float, z:Float):Transform {
        return new Transform(x, y, z, rotX, rotY, rotZ, scaleX, scaleY, scaleZ);
    }

    public function withRotation(x:Float, y:Float, z:Float):Transform {
        return new Transform(x, y, z, x, y, z, scaleX, scaleY, scaleZ);
    }

    public function withScale(x:Float, y:Float, z:Float):Transform {
        return new Transform(x, y, z, rotX, rotY, rotZ, x, y, z);
    }
}