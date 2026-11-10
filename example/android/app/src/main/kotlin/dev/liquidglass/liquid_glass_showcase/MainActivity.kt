package dev.liquidglass.liquid_glass_showcase

import android.os.Bundle
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.graphics.Bitmap
import android.view.PixelCopy
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Developer fixture only: copy this app's presented surface, without
        // converting the rendering surface or reading other apps/the display.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "dev.liquid_optics_flutter/renderer_test").setMethodCallHandler { call, result ->
            if (call.method != "captureSurface") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val surface = findFlutterSurface(window.decorView)
            if (Build.VERSION.SDK_INT < 24 || surface == null ||
                surface.width <= 0 || surface.height <= 0 ||
                surface.width.toLong() * surface.height > 16777216L) {
                result.error("surface_unavailable", "A visible Flutter SurfaceView and API 24+ are required", null)
                return@setMethodCallHandler
            }
            val bitmap = Bitmap.createBitmap(surface.width, surface.height, Bitmap.Config.ARGB_8888)
            try {
            PixelCopy.request(surface, bitmap, { status ->
                try {
                    if (status != PixelCopy.SUCCESS) {
                        result.error("pixel_copy_failed", "PixelCopy status=$status", null)
                    } else {
                        val pixels = IntArray(bitmap.width * bitmap.height)
                        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
                        val rgba = ByteArray(pixels.size * 4)
                        for (index in pixels.indices) {
                            val color = pixels[index]
                            rgba[index * 4] = (color ushr 16).toByte()
                            rgba[index * 4 + 1] = (color ushr 8).toByte()
                            rgba[index * 4 + 2] = color.toByte()
                            rgba[index * 4 + 3] = (color ushr 24).toByte()
                        }
                        val png = ByteArrayOutputStream()
                        if (call.argument<Boolean>("png") != false) {
                            check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, png)) {
                                "PNG encoding failed"
                            }
                        }
                        result.success(mapOf("width" to bitmap.width, "height" to bitmap.height,
                            "rgba" to rgba, "png" to png.toByteArray()))
                    }
                } catch (error: Exception) {
                    result.error("pixel_copy_encoding", error.toString(), null)
                } finally {
                    bitmap.recycle()
                }
            }, Handler(Looper.getMainLooper()))
            } catch (error: Exception) {
                bitmap.recycle()
                result.error("pixel_copy_request", error.toString(), null)
            }
        }
    }

    private fun findFlutterSurface(view: View): FlutterSurfaceView? {
        if (view is FlutterSurfaceView) return view
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                val surface = findFlutterSurface(view.getChildAt(index))
                if (surface != null) return surface
            }
        }
        return null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Applies only while this developer showcase/test activity is visible.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
