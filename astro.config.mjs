// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
	site: 'https://lethe-protocol.github.io',
	integrations: [
		starlight({
			title: 'pora',
			tagline: 'The passage where code enters, findings emerge, and vulnerability knowledge is destroyed.',
			// logo will be added when heliopora mascot image is ready
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/lethe-protocol' },
			],
			customCss: ['./src/styles/custom.css'],
			sidebar: [
				{
					label: 'Start Here',
					items: [
						{ label: 'What is pora?', slug: 'guides/what-is-pora' },
						{ label: 'Quick Start', slug: 'guides/quick-start' },
					],
				},
				{
					label: 'Vision & Strategy',
					autogenerate: { directory: 'vision' },
				},
				{
					label: 'Market Design',
					autogenerate: { directory: 'market' },
				},
				{
					label: 'Technical',
					autogenerate: { directory: 'technical' },
				},
				{
					label: 'Participate',
					items: [
						{ label: 'User Scenarios', slug: 'participate/user-scenarios' },
						{ label: 'Simulation Plan', slug: 'participate/simulation-test-plan' },
						{ label: 'Onboarding', slug: 'participate/onboarding' },
					],
				},
			],
		}),
	],
});
