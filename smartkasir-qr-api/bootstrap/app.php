<?php

declare(strict_types=1);

use App\Support\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        $exceptions->render(function (ValidationException $exception, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::validation($exception->errors());
        });

        $exceptions->render(function (AuthenticationException $exception, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::error('Tidak terautentikasi.', 401);
        });

        $exceptions->render(function (AuthorizationException $exception, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::error('Anda tidak memiliki izin.', 403);
        });

        $exceptions->render(function (NotFoundHttpException $exception, Request $request): ?JsonResponse {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::error('Data tidak ditemukan.', 404);
        });
    })->create();
