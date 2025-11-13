package;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import openfl.system.System;
import flixel.graphics.FlxGraphic;
import openfl.media.Sound;
import openfl.display3D.textures.Texture;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	// stealing my own code from psych engine
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];
	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}
	
	public static function excludeAsset(key:String)
		{
			if (!dumpExclusions.contains(key))
				dumpExclusions.push(key);
		}
	
		public static var dumpExclusions:Array<String> = [
			'assets/music/gameOver.$SOUND_EXT',
			'assets/music/breakfast.$SOUND_EXT',
		];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
		{
			// clear non local assets in the tracked assets list
			var counter:Int = 0;
			for (key in currentTrackedAssets.keys())
			{
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
				{
					var obj = currentTrackedAssets.get(key);
					if (obj != null)
					{
						obj.persist = false;
						obj.destroyOnNoUse = true;
						var isTexture:Bool = currentTrackedTextures.exists(key);
						if (isTexture)
						{
							var texture = currentTrackedTextures.get(key);
							texture.dispose();
							texture = null;
							currentTrackedTextures.remove(key);
						}
						@:privateAccess
						if (openfl.Assets.cache.hasBitmapData(key))
						{
							openfl.Assets.cache.removeBitmapData(key);
							FlxG.bitmap._cache.remove(key);
						}
						#if GARBAGE_COLLECTOR_INFO
						trace('removed $key, ' + (isTexture ? 'is a texture' : 'is not a texture'));
						#end
						obj.destroy();
						currentTrackedAssets.remove(key);
						counter++;
					}
				}
			}
			#if GARBAGE_COLLECTOR_INFO trace('removed $counter assets'); #end
			// run the garbage collector for good measure lmfao
			System.gc();
		}
	
		// define the locally tracked assets
		public static var localTrackedAssets:Array<String> = [];
	
		public static function clearStoredMemory(?cleanUnused:Bool = false)
		{
			// clear anything not in the tracked assets list
			@:privateAccess
			for (key in FlxG.bitmap._cache.keys())
			{
				final obj = FlxG.bitmap._cache.get(key);
				if (obj != null && !currentTrackedAssets.exists(key))
				{
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
				}
			}
	
			// clear all sounds that are cached
			for (key in currentTrackedSounds.keys())
			{
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
				{
					Assets.cache.clear(key);
					currentTrackedSounds.remove(key);
				}
			}
			// flags everything to be cleared out next unused memory clear
			localTrackedAssets = [];
		}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String)
	{
		return 'songs:assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	inline static public function inst(song:String)
	{
		return 'songs:assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	inline static public function image(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}
}
