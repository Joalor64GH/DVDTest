package;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;

import DVDHandler;

class PlayState extends FlxState
{
    var dvdLogo:FlxSprite;
    var colors = [
        [255, 255, 255],
        [6, 219, 22],
        [4, 151, 221],
        [244, 154, 94],
        [243, 95, 206],
        [33, 169, 141]
    ];
    var curColor:Int = 0;

    override public function create()
    {
        super.create();

        dvdLogo = new FlxSprite(0, 0);
        dvdLogo.loadGraphic(Paths.image('dvd'));
        dvdLogo.setGraphicSize(200, 5);
        dvdLogo.scale.y = dvdLogo.scale.x;
        dvdLogo.updateHitbox();
        dvdLogo.velocity.set(135, 95);
        dvdLogo.setColorTransform(0, 0, 0, 1, 255, 255, 255);
        dvdLogo.antialiasing = true;
        FlxG.state.add(dvdLogo);

        var text:FlxText = new flixel.text.FlxText(0, 0, 0, "Hello World", 64);
        text.screenCenter();
        add(text);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (dvdLogo.x > FlxG.width - dvdLogo.width || dvdLogo.x < 0) {
        dvdLogo.velocity.x = -dvdLogo.velocity.x;
        switchColor();
    } 
    if (dvdLogo.y > FlxG.height - dvdLogo.height || dvdLogo.y < 0) {
        dvdLogo.velocity.y = -dvdLogo.velocity.y;
        switchColor();
    }
    }

    function switchColor() 
    {
        curColor = (curColor + 1) % colors.length;
        dvdLogo.setColorTransform(0, 0, 0, 1, colors[curColor][0], colors[curColor][1], colors[curColor][2]);
    }
}