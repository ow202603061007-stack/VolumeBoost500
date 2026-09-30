(function () {
    "use strict";

    if (window.VolumeBoost500) return;

    const state = {
        gain: 1.0,
        context: null,
        nodes: new WeakMap()
    };

    function getContext() {
        if (!state.context) {
            const AudioContextClass = window.AudioContext || window.webkitAudioContext;
            if (!AudioContextClass) return null;
            state.context = new AudioContextClass();
        }
        return state.context;
    }

    async function resumeContext() {
        const ctx = getContext();
        if (!ctx) return;
        if (ctx.state === "suspended") {
            try { await ctx.resume(); } catch (_) {}
        }
    }

    function connectMedia(media) {
        if (!media || state.nodes.has(media)) return;

        const ctx = getContext();
        if (!ctx) return;

        try {
            const source = ctx.createMediaElementSource(media);
            const gain = ctx.createGain();
            gain.gain.value = state.gain;

            source.connect(gain);
            gain.connect(ctx.destination);

            state.nodes.set(media, { source, gain, ctx });

            const wake = () => { resumeContext(); };
            media.addEventListener("play", wake, { passive: true });
            media.addEventListener("playing", wake, { passive: true });
        } catch (_) {
            // A media element already owned by another Web Audio graph,
            // or an element that WebKit does not allow to be connected,
            // is left untouched.
        }
    }

    function scan(root) {
        if (!root) return;

        if (root.nodeType === 1) {
            const tag = root.tagName;
            if (tag === "AUDIO" || tag === "VIDEO") {
                connectMedia(root);
            }
            if (root.querySelectorAll) {
                root.querySelectorAll("audio, video").forEach(connectMedia);
            }
        }
    }

    function setVolume(multiplier) {
        const value = Math.max(0, Math.min(Number(multiplier) || 0, 5));
        state.gain = value;

        document.querySelectorAll("audio, video").forEach(media => {
            const item = state.nodes.get(media);
            if (!item) {
                connectMedia(media);
                return;
            }

            try {
                item.gain.gain.setTargetAtTime(value, item.ctx.currentTime, 0.01);
            } catch (_) {
                try { item.gain.gain.value = value; } catch (_) {}
            }
        });

        resumeContext();
    }

    const observer = new MutationObserver(mutations => {
        for (const mutation of mutations) {
            mutation.addedNodes.forEach(scan);
        }
    });

    function start() {
        scan(document.documentElement);
        observer.observe(document.documentElement, { childList: true, subtree: true });

        [500, 1500, 3000].forEach(ms => {
            setTimeout(() => scan(document.documentElement), ms);
        });

        document.addEventListener("click", resumeContext, { passive: true });
        document.addEventListener("touchend", resumeContext, { passive: true });
    }

    window.VolumeBoost500 = { setVolume };

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", start, { once: true });
    } else {
        start();
    }
})();
