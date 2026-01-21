import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';
import mermaid from 'astro-mermaid';

export default defineConfig({
  site: 'https://k8s.sudhanva.me',
  integrations: [
    sitemap(),
    mermaid(),
    starlight({
      title: 'OKE on OCI Always Free',
      description: 'Deploy a production-ready OKE (Oracle Kubernetes Engine) cluster on Oracle Cloud Infrastructure Always Free tier using Terraform, ArgoCD GitOps, Envoy Gateway, and automatic TLS certificates.',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/nsudhanva/k8s-oracle' },
      ],
      head: [
        {
          tag: 'meta',
          attrs: {
            name: 'keywords',
            content: 'oke, kubernetes, oracle cloud, oci, always free, terraform, argocd, gitops, envoy gateway, free kubernetes, arm64, ampere, oracle kubernetes engine',
          },
        },
        {
          tag: 'meta',
          attrs: {
            name: 'author',
            content: 'Sudhanva Narayana',
          },
        },
        {
          tag: 'meta',
          attrs: {
            property: 'og:image',
            content: 'https://k8s.sudhanva.me/og-image.svg',
          },
        },
        {
          tag: 'meta',
          attrs: {
            property: 'og:type',
            content: 'website',
          },
        },
        {
          tag: 'meta',
          attrs: {
            name: 'twitter:card',
            content: 'summary_large_image',
          },
        },
        {
          tag: 'meta',
          attrs: {
            name: 'twitter:image',
            content: 'https://k8s.sudhanva.me/og-image.svg',
          },
        },
        {
          tag: 'link',
          attrs: {
            rel: 'canonical',
            href: 'https://k8s.sudhanva.me',
          },
        },
        {
          tag: 'script',
          attrs: {
            type: 'application/ld+json',
          },
          content: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'TechArticle',
            'headline': 'OKE on Oracle Cloud Always Free Tier',
            'description': 'Complete guide to deploying a free Kubernetes cluster on Oracle Cloud using OKE, Terraform, and GitOps.',
            'author': {
              '@type': 'Person',
              'name': 'Sudhanva Narayana',
            },
            'publisher': {
              '@type': 'Organization',
              'name': 'k8s-oracle',
              'url': 'https://github.com/nsudhanva/k8s-oracle',
            },
            'mainEntityOfPage': 'https://k8s.sudhanva.me',
          }),
        },
      ],
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Prerequisites', slug: 'getting-started/prerequisites' },
            { label: 'Installation', slug: 'getting-started/installation' },
            { label: 'Configuration', slug: 'getting-started/configuration' },
          ],
        },
        {
          label: 'Architecture',
          items: [
            { label: 'Overview', slug: 'architecture/overview' },
            { label: 'Always Free Tier', slug: 'architecture/always-free' },
            { label: 'Secrets Management', slug: 'architecture/secrets-management' },
            { label: 'Ingress With Load Balancer', slug: 'architecture/ingress' },
            { label: 'Networking', slug: 'architecture/networking' },
            { label: 'GitOps', slug: 'architecture/gitops' },
            { label: 'Gemma LLM', slug: 'architecture/gemma-llm' },
            { label: 'Open WebUI', slug: 'architecture/open-webui' },
          ],
        },
        {
          label: 'Operation',
          items: [
            { label: 'Accessing Cluster', slug: 'operation/accessing-cluster' },
            { label: 'Adding Apps', slug: 'operation/adding-apps' },
            { label: 'Cluster Recreation', slug: 'operation/cluster-recreation' },
          ],
        },
        {
          label: 'Troubleshooting',
          items: [
            { label: 'Common Issues', slug: 'troubleshooting/common-issues' },
          ],
        },
      ],
    }),
  ],
});