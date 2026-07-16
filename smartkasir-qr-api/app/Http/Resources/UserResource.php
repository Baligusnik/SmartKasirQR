<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Resource untuk menampilkan data pengguna tanpa atribut sensitif.
 *
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string $role
 */
class UserResource extends JsonResource
{
    /**
     * Mengubah model User menjadi array response API.
     *
     * @param  Request  $request  Request HTTP yang sedang diproses.
     * @return array<string, mixed> Data pengguna aman untuk response.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role,
        ];
    }
}
