@props(['type' => 'info', 'message'])

<div class="alert alert-{{ $type }}" role="status">
    {{ $message }}
</div>
